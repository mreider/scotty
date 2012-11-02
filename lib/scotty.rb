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
require 'golang_parser'
require 'golang_std_lib'
require 'golang_repositories'

module Scotty

  class Scotty < Thor
    include Errors

    FOUND_MASTER_CSV = 'found_master_tickets.csv'
    MISSING_MASTER_CSV = 'missing_master_tickets.csv'
    FOUND_USE_CSV = 'found_use_tickets.csv'
    MISSING_USE_CSV = 'missing_use_tickets.csv'

    GITLOG_DATE=/^Date:.*?(?<year>\d{4})/

    class Component
      attr_accessor :name, :version, :subdir, :download_url, :category, :result
      def initialize(name, version, subdir, download_url, category)
        self.name = name
        self.version = version
        self.subdir = subdir
        self.download_url = download_url
        self.category = category
        @key = nil
      end
      def id
        self.result['id'] if self.result
      end
      def sz_name
        self.name.downcase
      end
      def sz_version
        self.version.downcase
      end
      def sz_args
        { :name => self.sz_name,
          :version => self.sz_version,
          :category => self.category }
      end
      def key
        @key = [ sz_name, ':', sz_version ].join unless @key
        @key
      end
      def sz_product
        "cf-#{self.subdir}"
      end
    end

    # Initialize opens a yaml file from ~/.scotty and loads it into the :config hash
    # If no ~/.scotty exists, it will create one. Sorry to clutter up your home directory
    def initialize(*args)
      super
      my_init
    end

    desc "scan","scan for existing tickets in Scotzilla"
    method_option :ticket_type, :default => "master", :aliases => "-r", :desc => "sets request type to search for (master or use)"

    def scan
      @ticket_finder = TicketFinder.new(@config['host'], "/" + @config['path'], @config['port'],
                                        @config['use_ssl'], @config['user'], @config['password'])
      # search tickets for master or use tickets...
      case options.ticket_type
        when 'master'
          # master tickets require that software be in a directory to scan
          error(5) unless File::directory?('software')
          search_master_tickets
        when 'use'
          search_use_tickets
        else
          error(7)
      end
    end

    desc "create","create tickets based on spreadsheets for not found (master) or found (use) tickets"
    method_option :ticket_type, :default => "master", :aliases => "-r", :desc => "sets request type to create (master or use)"

    def create

      case options.ticket_type

        when "master"
          info "Parsing missing_master_tickets.csv and creating new master tickets"
          CSV.foreach("missing_master_tickets.csv", :headers => :first_row, :return_headers => false) do |row_data|
            create_master_ticket({ :name => row_data[1],
                                   :version => row_data[2],
                                   :license_text => row_data[3],
                                   :description => row_data[4],
                                   :license_name => row_data[5],
                                   :source_url => row_data[6],
                                   :category => row_data[7],
                                   :modified => row_data[8],
                                   :username => @config['user'],
                                   :password => @config['password'] })
          end

        when "use"
          info "Parsing missing_use_tickets.csv and creating new tickets"
          CSV.foreach("missing_use_tickets.csv", :headers => :first_row, :return_headers => false) do |row_data|
            create_use_ticket({ :product => row_data[1],
                                :version => @config['product_version'],
                                :mte => row_data[0].to_i,
                                :interaction => @config['interaction'],
                                :description => @config['description'],
                                :username => @config['user'],
                                :password => @config['password'] })
          end

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

    private

    def my_init
      @components = {}
      stdin, stdout, stderr = Open3.popen3('cat ~/.scotty')
      @yaml = ""
      stdout.each_line { |line| @yaml = @yaml + line }
        if(stderr.gets =~ /No such file or directory/)
          system("wget -O ~/.scotty http://vmcpush.com/scotty.txt -q")
          error(3)
        end
      @config = YAML::load(@yaml)
      @scotzilla = SZ_API.new(@config['host'], "/" + @config['path'], @config['port'],
                              @config['use_ssl'], @config['user'], @config['password'])
    end

    def parse_gpl
      traverse
    end

    def search_master_tickets
      traverse
      checked = @ticket_finder.master_results.partition {|c| c.result['stat'] == 'ok'}
      write_found_master_tickets(checked[0])
      write_missing_master_tickets(checked[1])
      info "Check the spreadsheet, modify it, and run 'scotty scan -r use' to see how many use tickets are available"
    end

    def search_use_tickets
      info "Parsing #{FOUND_MASTER_CSV} and checking for use tickets in Scotzilla"
       CSV.foreach(FOUND_MASTER_CSV, :headers => :first_row, :return_headers => false) do |row_data|
         @ticket_finder.find_use({ :product => row_data[9],
                                   :version => @config['product_version'],
                                   :mte => row_data[0].to_i})
       end
       checked = @ticket_finder.use_results.partition{|t| t['stat'] == 'ok'}
       write_found_use_tickets(checked[0])
       write_missing_use_tickets(checked[1])
    end

    def info(message)
      puts "[INFO] " + message
    end

    def create_master_ticket(args)
      result = @scotzilla.create_master_ticket(args)
      puts result
      result
    end

    def create_use_ticket(args)
      result = @scotzilla.create_use_ticket(args)
      puts result
      result
    end

    def write_found_master_tickets(components)
      counter = 0
      CSV.open(FOUND_MASTER_CSV, 'wb') do |csv|
        csv << ['id','name','version','license_text','description','license_name','source_url','category','is_modified','repo','sz_product']
        components.each { |c|
            counter +=  1
            csv << [c.id, c.name, c.version, @config['license_text'], '', @config['license_name'], c.download_url, c.category, 'No', c.subdir, c.sz_product]
        }
      end
      info "Wrote #{counter} records to #{FOUND_MASTER_CSV}"
    end

    def write_missing_master_tickets(components)
      counter = 0
      CSV.open(MISSING_MASTER_CSV, 'wb') do |csv|
        csv << ['id','name','version','license_text','description','license_name','source_url','category','is_modified','repo','sz_product']
        components.map { |c|
            counter +=  1
            data = c.result['data']
            csv << ['', data[0], data[1], @config['license_text'], '', @config['license_name'], c.download_url, data[2], '', c.subdir, c.sz_product]
        }
      end
      info "Wrote #{counter} records to #{MISSING_MASTER_CSV}"
    end

    def write_found_use_tickets(tickets)
      counter = 0
      CSV.open(FOUND_USE_CSV, 'wb') do |csv|
        csv << ['mte','product','version','id','interaction','description','is_modified','features','status','resolution']
        counter = 0
        tickets.each {|elem|
            counter += 1
            csv << [elem['mte'],elem['product'],elem['version'],"","","","",""]
            elem['requests'].each {|item|
              csv << ['','','',item['id'], item['interactions'].join,@config['description'],
                      item['modified'],item['features'].join,item['status'],item['resolution']]
            }
        }
      end
      info "Wrote #{counter} records to #{FOUND_USE_CSV}"
    end

    def write_missing_use_tickets(tickets)
      counter = 0
      CSV.open(MISSING_USE_CSV, 'wb') do |csv|
        csv << ['mte','product','version','id','interaction','description','is_modified','features']
        tickets.each {|elem|
          counter += 1
          csv << [elem['data'][2], elem['data'][0],elem['data'][1],'','',elem ? elem.to_s : '']
        }
      end
      info "Wrote #{counter} records to #{MISSING_USE_CSV}"
    end

    def traverse
      found_components = false
      # First let's look for some ruby and node
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
          if file == 'Gemfile.lock'
            found_components = true
            parse_gemfile_lock(File.expand_path(path))
          elsif file == 'package.json'
            found_components = true
            parse_node_packages(File.expand_path(path))
          elsif File.extname(file) == '.go'
            found_components = true
            parse_golang_packages(File.expand_path(path))
          end
        end
      end

      #now let's look for some maven
      top_level_pom = Dir["software" + '/*/pom.xml']
      unless(top_level_pom.nil?)
        found_components = true
        parse_maven_packages(top_level_pom)
      end

      if(found_components == false)
        error(1)
      end
    end

    def push_component(name, version, subdir, download_url)
      component = Component.new(name, version, subdir, download_url, @config['category'])
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
      push_component(name,
                     version.gsub("x", "0").gsub(">=","").gsub("*","1.0.0"), #some of these versions are 1.0.x
                     subdir,
                     "http://search.npmjs.org/#/#{name}")
    end

    def parse_gemfile_lock(file_path)
      info "Parsing " + file_path
      subdir = component_dir_from_path(file_path)
      f = File.open(file_path)
      results = f.readlines
      f.close
      results.each do |n|
        if(n =~ /\((?:(\d+)\.)?(?:(\d+)\.)?(\*|\d+)\)/)
          raw_materials = n.split("(")
          name = raw_materials[0].strip!
          version = (raw_materials[1].strip!).gsub(/\)/,"")
          push_component(name, version, subdir, "http://rubygems.org/gems/#{name}")
        end
      end
    end

    def parse_maven_packages(top_level_pom)
      top_level_pom.each {|top|
        info "Running mvn install for " + top
        top_minus = top.chomp("pom.xml")
        system("cd " + top_minus + ";mvn install > /dev/null ;mvn dependency:list | tee delete_me.txt")
        info "Parsing dependency list..."
        f = File.open(top_minus+"delete_me.txt")
        results = f.readlines
        f.close
        results.each do |n|
          if(n =~ /:(.*):.*:(.*):/)
            raw_materials = n.split(":")
            raw_materials[0] = raw_materials[0].gsub(/\[INFO\]/,"")
            raw_materials[0] = raw_materials[0].strip
            raw_materials[1] = raw_materials[1].strip
            raw_materials[3] = raw_materials[3].strip
            if (raw_materials[3].size == 1)
              raw_materials[3] = raw_materials[3] + ".0.0"
            end
            push_component(raw_materials[1], raw_materials[3], top_minus, "http://search.maven.org/#search|ga|1|g:#{raw_materials[0]}")
          end
        end
      }
    end

    def parse_golang_packages(file_path)
      info "Parsing " + file_path
      subdir = component_dir_from_path(file_path)

      parser = GolangParser.new
      import_paths = parser.get_import_paths(file_path)
      GolangStdLib.remove_standard_packages(import_paths).each do |path|
        # if path does not contain any host prefix, assume this dep is one of ours and ignore
        push_component(File.basename(path), '?.?.?', subdir, GolangRepositories.map_download_url(path)) if path.include?('/')
      end
    end

    def component_dir_from_path(path)
      path.match(/software\/(?<dir>.*?)\//)['dir']
    end

    #end of class
  end

end
