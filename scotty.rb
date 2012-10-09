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
require_relative 'sz_api'

class Scotty < Thor

  # Initialize opens a yaml file from ~/.scotty and loads it into the :config hash
  # If no ~/.scotty exists, it will create one. Sorry to clutter up your home directory  
  def initialize(*args)
    super
    my_init
  end

  desc "scan","scan for existing tickets in Scotzilla"
  method_option :ticket_type, :default => "master", :aliases => "-r", :desc => "sets request type to search for (master or use)"

  def scan
    # master tickets require that software be in a directory to scan
    if(options.ticket_type == "master")
      unless(File::directory?( "software"))
        error(5)
      end
    end
    
    # search tickets for master or use tickets...
    search_tickets(options.ticket_type.downcase)

  end

  desc "create","create tickets based on spreadsheets for not found (master) or found (use) tickets"
  method_option :ticket_type, :default => "master", :aliases => "-r", :desc => "sets request type to create (master or use)"

  def create

    case options.ticket_type

      when "master"
        info "Parsing missing_master_tickets.csv and creating new master tickets"
        CSV.foreach("missing_master_tickets.csv", :headers => :first_row, :return_headers => false) do |row_data|
          create_tickets("master", { :name => row_data[1], 
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
          create_tickets("use", { :product => row_data[1],
          		                    :version => @config['product_version'], 
          		                    :mte => row_data[0].to_i,
          		                    :interaction => @config['interaction'],
          		                    :description => @config['description'],
          		                    :username => @config['user'],
          		                    :password => @config['password'] })
        end
        write_to_csv("use")
      else
        error(7)
      end
  end
  
  private 

  def my_init
    @components = []
    @checked_components = []
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

  def search_tickets(ticket_type)
    case ticket_type
      when "master"
        traverse
        @components.uniq! { |e| e[:name].downcase + e[:version].to_str.downcase }
        info "Duplicates removed"
        info "Searching for existing master tickets in Scotzilla"
        @components.each do |component|
        puts component[:name]
        result = find_tickets("master", { :name => component[:name].downcase,
                                          :version => component[:version].downcase, 
                                          :category => @config['category'] })
        result['download_url'] = component[:download_url]
        begin
          if component[:subdir].to_s =~ /"/
            tmp_str = "cf-" + component[:subdir].to_s.match('software\/(.*)"')[1]
          else
            tmp_str = "cf-" + component[:subdir].to_s.match('software\/(.*)\/')[1]
          end
        rescue
          tmp_str = component[:subdir]
        end
        result['subdir'] = tmp_str
        @checked_components.push(result)
        end
        write_to_csv("master")
      when "use"
        info "Parsing found_master_tickets.csv and checking for use tickets in Scotzilla"
        CSV.foreach("found_master_tickets.csv", :headers => :first_row, :return_headers => false) do |row_data|
          result = find_tickets("use", { :product => row_data[9],
                                         :version => @config['product_version'],
                                         :mte => row_data[0].to_i})
          @checked_components.push(result)
        end
        write_to_csv("use")
      else
        error(7)
    end 
  end

  def info(message)
    puts "[INFO] " + message
  end

  def create_tickets(tick_type, args)  	
    result = nil
    if(tick_type == "master")
      result = @scotzilla.create_master_ticket(args)
  	end
    if(tick_type == "use")
      result = @scotzilla.create_use_ticket(args)
    end
    puts result
    return result
  end

  def find_tickets(tick_type, args)
  	result = nil
    if(tick_type == "master")
      result = @scotzilla.find_master_ticket(args)
    end
    if(tick_type == "use")
      result = @scotzilla.find_use_ticket(args)
    end
    puts result
    return result
  end

  def write_to_csv(ticket_type)

    if(ticket_type == "master")
      CSV.open("found_master_tickets.csv", "wb") do |csv|
        csv << ["id","name","version","license_text","description","license_name","source_url","category","is_modified","repo"] 
        counter = 0
        @checked_components.each {|elem| 
            if(elem['stat'] == "ok")
               counter =  counter + 1
               #Clean up [Master Ticket] rest-client - 1.6.7 to be three seperate columns
               elem['desc'].slice! "[Master Ticket] "
               tmp = elem['desc'].split
               tmp.delete_at(1)
               # Shove stuff in a CSV
               csv << [elem['id'],tmp[0].downcase,tmp[1].downcase,@config['license_text'],"",
                 @config['license_name'],elem['download_url'],@config['category'],"No",elem['subdir']] 
            end
          }
      info "Wrote " + counter.to_s + " records to found_master_tickets.csv"
      end
      counter = 0
      CSV.open("missing_master_tickets.csv", "wb") do |csv|
        csv << ["id","name","version","license_text","description","license_name","source_url","category","is_modified","repo"]
        @checked_components.each {|elem| 
          if(elem['stat'] == "err")
            counter = counter + 1
            version = elem['data'][1]
            version.downcase unless not version.respond_to? :downcase
            csv << ["", elem['data'][0].downcase, version, @config['license_text'], "", @config['license_name'],
                    elem['download_url'], elem['data'][2], "No", elem['subdir']]
          end
        }
      end
      info "Wrote " + counter.to_s + " records to missing_master_tickets.csv"
      info "Check the spreadsheet, modify it, and run 'scotty scan -r use' to see how many use tickets are available"
    
    elsif(ticket_type == "use")
      counter = 0
      CSV.open("found_use_tickets.csv", "wb") do |csv|
        csv << ["mte","product","version","id","interaction","description","is_modified","features"]
        counter = 0
        @checked_components.each {|elem| 
            if(elem['stat'] == "ok")
              counter =  counter + 1
               csv << [elem['mte'],elem['product'],elem['version'],"","","","",""]
                 elem['requests'].each {|item|
                   csv << ["","","",item['id'], item['interactions'].join,@config['description'],
                   item['is_modified'],item['features'].join] 
                 }
              
            end
          }
      end
      info "Wrote " + counter.to_s + " records to found_use_tickets.csv"

      counter = 0
      CSV.open("missing_use_tickets.csv", "wb") do |csv|
        csv << ["mte","product","version","id","interaction","description","is_modified","features"]
        counter = 0
        @checked_components.each {|elem| 
            if(elem['stat'] == "err")
               counter =  counter + 1
               csv << [elem['data'][2], elem['data'][0],elem['data'][1]]
            end
          }
      end
      info "Wrote " + counter.to_s + " records to missing_use_tickets.csv"
    end
  end

  def traverse
    found_components = false
    # First let's look for some ruby and node
      Find.find("software") do |path|
        if FileTest.directory?(path)
          if File.basename(path)[0] == ?.
            Find.prune       # Don't look any further into this directory.
          else
            next
          end
        else
          if File.basename(path) == "Gemfile.lock"
            found_components = true
            parse_gemfile_lock(File.expand_path(path))
          elsif File.basename(path) == "package.json"
            found_components = true
            parse_node_packages(File.expand_path(path))
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

  def parse_node_packages(file_path)
    info "Parsing " + file_path
    subdir = file_path.scan(/\/software\/\w*/)
    json = File.read(file_path)
    begin
      result = JSON.parse(json)
    rescue
      return
    end

    # push the package itself
    push_node_component(subdir, result['name'], result['version']) unless result['name'].nil?
    
    # push the dependency and devDependency hashes
    result['dependencies'].each { |k,v| push_node_component(subdir, k, v) } unless result['dependencies'].nil?
    result['devDependencies'].each { |k,v| push_node_component(subdir, k, v) } unless result['devDependencies'].nil?
      
  end

  def push_node_component(subdir, name, version)
  	@components << {
      :subdir => subdir,
      :download_url => "http://search.npmjs.org/#/" + name,
      :name => name,
      :version => version.gsub("x", "0").gsub(">=","").gsub("*","1.0.0") #some of these versions are 1.0.x 		
  	}
  end

  def parse_gemfile_lock(file_path)
    info "Parsing " + file_path
    subdir = file_path.scan(/\/software\/\w*/)
    f = File.open(file_path)
    results = f.readlines
    f.close
    results.each do |n|
      if(n =~ /\((?:(\d+)\.)?(?:(\d+)\.)?(\*|\d+)\)/)
        raw_materials = n.split("(")
        to_be_pushed = Hash.new
        to_be_pushed[:subdir] = subdir
        to_be_pushed[:name] = raw_materials[0].strip!
        to_be_pushed[:download_url] = "http://rubygems.org/gems/" + to_be_pushed[:name]
        t = (raw_materials[1].strip!)
        to_be_pushed[:version] = t.gsub(/\)/,"")
        @components.push(to_be_pushed)
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
          to_be_pushed = Hash.new
          to_be_pushed[:subdir] = top_minus
          to_be_pushed[:download_url] = "http://search.maven.org/#search|ga|1|g:" + raw_materials[0]
          to_be_pushed[:name] = raw_materials[1]
          to_be_pushed[:version] = raw_materials[3]
          @components.push(to_be_pushed)
        end
      end
    }
  end

  def error(code)
    case code
      when 0
         puts "[ERROR] An uknown error occurred"
      when 1
         puts "[ERROR] No package file found in " + options.directory
         puts "[ERROR] for Maven there must be a pom.xml (and mvn installed)"
         puts "[ERROR] for Node there must be a package.json" 
         puts "[ERROR] for Ruby there must be a Gemfile.lock (run bundler)"
      when 2
         puts "[ERROR] A SocketError occurred. Make sure you have a VPN connection if you are not on the VMware network"
      when 3
         puts "[ERROR] A scotty config file could not be found"
         puts "[INFO]  A config file was written to ~/.scotty"
      when 5
         puts "[ERROR] Cannot find " + options.directory
      when 7
         puts "[ERROR] Invalid ticket_type - values can be either 'master' or 'use'" 
     end
    puts "\n\n"
    exit
  end
#end of class
end

Scotty.start

