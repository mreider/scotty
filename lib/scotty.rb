#!/usr/bin/env ruby
# This is Scotty
# A script for accessing VMware's software licensing platform (Scotzilla)
# Copyright 2012 © VMware
# Authors: Matthew Reider (mreider@vmware.com)

require 'xmlrpc/client'
require 'yaml'
require 'find'
require 'csv'
require 'json'
require 'open3'
require 'thor'

require 'errors'
require 'sz_api'
require 'ticket_finder'
require 'ticket_persistor'
require 'golang_parser'
require 'golang_std_lib'
require 'golang_repositories'
require 'node_ver'
require 'code_component'

module Scotty

  # load config
  #
  # Initialize opens a yaml file from ~/.scotty and loads it into the :config hash
  # If no ~/.scotty exists, it will create one. Sorry to clutter up your home directory
  #
  stdin, stdout, stderr = Open3.popen3('cat ~/.scotty')
  yaml = ''
  stdout.each_line { |line| yaml << line }
  if stderr.gets =~ /No such file or directory/
    system("wget -O ~/.scotty http://vmcpush.com/scotty.txt -q")
    error(3)
  else
    @@config = YAML::load(yaml)
  end

  #
  # Returns the current configuration object
  #
  def self.config
    @@config
  end

  class Scotty < Thor
    include Errors

    GITLOG_DATE=/^Date:.*?(?<year>\d{4})/

    def initialize(*args)
      super
      @components = {}             # TODO: get rid of this
      @config = ::Scotty.config    # TODO: use module config throughout
      @scotzilla = SZ_API.new(@config['host'], "/" + @config['path'], @config['port'],
                              @config['use_ssl'], @config['user'], @config['password'])
    end

    desc "scan","scan for existing tickets in Scotzilla"
    method_option :ticket_type, :default => "master", :aliases => "-r", :type => :string, :desc => "Sets request type to search for (master, use or all)"
    method_option :exclude_lang, :aliases => "-L", :type => :array, :desc => "Exclude languages from the search"

    def scan
      @ticket_finder = TicketFinder.new(@config['host'], "/" + @config['path'], @config['port'],
                                        @config['use_ssl'], @config['user'], @config['password'])

      search_langs = LangOptions.new(options.exclude_lang).converse

      # search tickets for master or use tickets...
      case options.ticket_type
        when 'master'
          search_master_tickets(search_langs)
        when 'use'
          search_use_tickets(search_langs)
        when 'all'
          search_master_tickets(search_langs)
          search_use_tickets(search_langs)
        else
          error(7)
      end
    end

    desc "create","create tickets based on spreadsheets for not found (master) or found (use) tickets"
    method_option :ticket_type, :default => "master", :aliases => "-r", :desc => "sets request type to create (master or use)"

    def create

      case options.ticket_type

        when "master"
          create_master_tickets
        when "use"
          create_use_tickets
        else
          error(7)
      end
    end

    desc "copyright_years", "prints the copyright years for each repo to STDOUT"

    def copyright_years

      Dir.chdir('./software')

      Dir.entries('.').sort { |f1,f2| f1 <=> f2 }.each do |f|
        next if f[0] == '.'
        next if File.file? f

        Dir.chdir(f)

        first = last = nil

        `git --no-pager log`.each_line do |line|
          if match = GITLOG_DATE.match(line)
            first = match['year'] unless first
            last = match['year']
          end
        end

        puts "#{f} " + first.eql?(last) ? first : "#{last}-#{first}"

        Dir.chdir('..')
      end
      Dir.chdir('..')
    end

    desc "print_counts", "print the number of ticket records in each file to STDOUT"

    def print_counts
      [ FOUND_MASTER_CSV, MISSING_MASTER_CSV,
        FOUND_USE_CSV, MISSING_USE_CSV ].select { |f| File.exists? f }.each  do |csv|
        lines = `wc -l '#{csv}'`.to_i - 1  # header row
        info "#{lines} #{csv}"
      end
    end

    private

    def search_master_tickets(languages)
      # scanning master tickets require that software be in a directory to scan
      error(5, 'software') unless File::directory?('software')

      traverse(languages)
      checked = @ticket_finder.master_results.partition {|c| c.result['stat'] == 'ok'}
      TicketPersistor.write_found_master_tickets(checked[0])
      TicketPersistor.write_missing_master_tickets(checked[1])
      info "Check the spreadsheet, modify it, and run 'scotty scan -r use' to see how many use tickets are available"
    end

    def search_use_tickets(languages)
      # scanning use tickets requires the found master tickets csv
      error(5, FOUND_MASTER_CSV) unless File.exists? FOUND_MASTER_CSV

      info "Parsing #{FOUND_MASTER_CSV} and checking for use tickets in Scotzilla"
      TicketPersistor.read_found_master_tickets do |ticket|
        next unless languages.include?(ticket[:language])
        @ticket_finder.find_use({ :product => ticket[:sz_product],
                                  :version => @config['product_version'],
                                  :mte => ticket[:id] })
      end
      checked = @ticket_finder.use_results.partition{|t| t['stat'] == 'ok'}
      TicketPersistor.write_found_use_tickets(checked[0])
      TicketPersistor.write_missing_use_tickets(checked[1])
    end

    def info(message)
      puts "[INFO] " + message
    end

    def create_master_tickets
      info "Parsing missing_master_tickets.csv and creating new master tickets"
      TicketPersistor.read_missing_master_tickets do |data|
        data[:username] = @config['user']
        data[:password] = @config['password']
        result = @scotzilla.create_master_ticket(data)
        puts "Created? #{result}"
      end
    end

    def create_use_tickets
      info "Parsing missing_use_tickets.csv and creating new tickets"
      TicketPersistor.read_missing_use_tickets do |data|
        data[:username] = @config['user']
        data[:password] = @config['password']
        result = @scotzilla.create_use_ticket(data)
        puts "Created? #{result}"
      end
    end

    def traverse(languages)
      # first let's look for some ruby and node
      Find.find("software") do |path|
        file = File.basename(path)
        if FileTest.directory?(path)
          if file[0] == ?.
            # don't look any further into this directory.
            Find.prune
          else
            next
          end
        else
          if languages.ruby? && file == 'Gemfile.lock'
            parse_gemfile_lock(File.expand_path(path))

          elsif languages.node? && file == 'package.json'
            parse_node_packages(File.expand_path(path))

          elsif languages.golang? && File.extname(file) == '.go'
            parse_golang_packages(File.expand_path(path))
          end
        end
      end

      # now let's look for some maven
      parse_maven_packages(Dir['software/*/pom.xml']) if languages.java?

    end

    def push_component(component)
      unless @components.include? component.key
        puts "Found #{component.name} #{component.version} in #{component.subdir}"
        @components[component.key] = component
        @ticket_finder.find_master(component)
      end
    end

    def parse_node_packages(file_path)
      info "Parsing " + file_path
      subdir = component_dir_from_path(file_path)
      json = File.read(file_path)
      begin
        result = JSON.parse(json)
      rescue
        return
      end

      # push the package itself
      push_node_component(result['name'], result['version'], subdir) unless result['name'].nil?

      # push the dependency and devDependency hashes
      result['dependencies'].each { |k,v| push_node_component(k, v, subdir) } unless result['dependencies'].nil?
      result['devDependencies'].each { |k,v| push_node_component(k, v, subdir) } unless result['devDependencies'].nil?

    end

    def push_node_component(name, version, subdir)
      ver = NodeVer::parse(version) || "INVALID_VERSION"
      push_component(NodeComponent.new(name, ver, subdir, "http://search.npmjs.org/#/#{name}"))
    end

    RUBY_NAME_VERSION = /^ {4}(?<name>.*?)\s\((?<version>(\d+\.)?(\d+\.)?(\*|\d+)?)\)/

    def parse_gemfile_lock(file_path)
      info "Parsing " + file_path
      subdir = component_dir_from_path(file_path)
      File.open(file_path) do |f|
        f.each do |line|
          if match = RUBY_NAME_VERSION.match(line)
            push_component(RubyComponent.new(match[:name], match[:version], subdir, "http://rubygems.org/gems/#{match[:name]}"))
          end
        end
      end
    end

    MAVEN_NAME_VERSION = /^\[INFO\]\s{4}([^:]+)(?::([^:]*))(?::[^:]*)(?::(\d+(?:\.\d+(?:\.\d+(?:\.\d+)?)?)?(?:[^:]*)))/

    def parse_maven_packages(top_level_poms)
      top_level_poms.each do |top|
        info "Running mvn install for " + top
        top_minus = top.chomp("pom.xml")
        system("cd " + top_minus + ";mvn install > /dev/null ;mvn dependency:list | tee delete_me.txt")
        info "Parsing dependency list..."
        File.open(top_minus + 'delete_me.txt') do |f|
          f.each do |line|
            if MAVEN_NAME_VERSION =~ line
              pkg, name, ver = $1, $2, $3
              ver << ".0.0" if ver.length == 1
              push_component(JavaComponent.new(name, ver, component_dir_from_path(top_minus), "http://search.maven.org/#search|ga|1|g:#{pkg}"))
            end
          end
        end
      end
    end

    def parse_golang_packages(file_path)
      info "Parsing " + file_path
      subdir = component_dir_from_path(file_path)
      parser = GolangParser.new
      import_paths = parser.get_import_paths(file_path)
      GolangStdLib.remove_standard_packages(import_paths).each do |path|
        # TODO: get version
        # $ git show -s --format="%ci"
        # 2012-10-17 09:19:08 -0700
        #
        # TODO: munge ISO 8601 date to US format
        #

        # TODO: if path does not contain any host prefix, assume this dep is one of ours and ignore
        download_url = GolangRepositories.map_download_url(path) if path.include?('/')
        push_component(GoComponent.new(File.basename(path), '?.?.?', subdir, download_url))
      end
    end

    def component_dir_from_path(path)
      path.match(/software\/(?<dir>.*?)\//)['dir']
    end

  #end of class
  end

  class LangOptions

    def initialize(opts)
      return if opts.nil?
      opts = opts.split(/\s+/) if opts.is_a? String

      opts.each do |o|
        @java = true if is_java?(o)
        @node = true if is_node?(o)
        @ruby = true if is_ruby?(o)
        @go = true if is_go?(o)
      end
    end

    def converse
      opts = []
      opts << 'java' unless @java
      opts << 'node' unless @node
      opts << 'ruby' unless @ruby
      opts << 'go' unless @go
      LangOptions.new(opts)
    end

    def java?
      @java
    end

    def node?
      @node
    end

    def ruby?
      @ruby
    end

    def golang?
      @go
    end

    def any?
      @java || @node || @ruby || @go
    end

    def include?(lang)
      return @java if is_java?(lang)
      return @node if is_node?(lang)
      return @ruby if is_ruby?(lang)
      return @go if is_go?(lang)
    end

    def inspect
      "<LangOptions java:#{@java} node:#{@node} ruby:#{@ruby} go:#{@go}>"
    end

    private

    def is_java?(s)
      s == 'java'
    end

    def is_node?(s)
      s =~ /^node(?:js)?$/  # node | nodejs
    end

    def is_ruby?(s)
      s == 'ruby'
    end

    def is_go?(s)
      s =~ /^go(?:lang)?$/  # go | golang
    end

  end

end