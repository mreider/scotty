#!/usr/bin/env ruby
#
# Copyright (c) VMware Inc. 2012
#

require 'csv'
require 'json'
require 'net/http'
require 'uri'

class Archiver
	
	ARC_DIR='artefacts'
	
	def initialize
	end

	def get_rubygem(name, version)
		# e.g. http://rubygems.org/downloads/addressable-2.2.5.gem
		gem_uri = URI("http://rubygems.org/downloads/#{name}-#{version}.gem")
		
		puts "getting gem #{gem_uri}"
		download_file(gem_uri)
	end
	
	def get_node_package(name, version)		
		tarball_uri = nil
		
		Net::HTTP.start('registry.npmjs.org') do |http|
			res = http.get("/#{name}/#{version}")
			json = JSON.parse(res.body)
			return false if json['error']
		  tarball_uri = URI(json['dist']['tarball'])
		end

		puts "getting npm #{tarball_uri}"
		download_file(tarball_uri)
	end
	
	def get_javasource(name, version)
		jar_uri = URI("http://search.maven.org/remotecontent")
		
		# smelly case munging...
		search_uri=URI("http://search.maven.org/solrsearch/select?q=a:%22#{name}%22%20AND%20v:%22#{version.to_str.upcase}%22%20AND%20p:%22jar%22&wt=json")
		
		Net::HTTP.start(search_uri.host) do |http|
			res = http.get("#{search_uri.path}?#{search_uri.query}")
			json = JSON.parse(res.body)
			
      # assert json['response']['docs'] is a single element array
      docs = json['response']['docs']
      return false unless docs.length > 0
      	
      doc = json['response']['docs'][0]
			group = doc["g"]
			artefact = doc['a']
			version = doc['v']
			
			filepath = "filepath=" << group.gsub(/\./, '/') << "/" << artefact << "/" << \
				         version << "/" << artefact << "-" << version << "-sources.jar"

		  jar_uri.query = filepath
		end
		
		puts "getting jar #{jar_uri}"
    download_file(jar_uri)
	end
	
	private
	
	def download_file(uri)
		begin
			f = open(File.join(ARC_DIR, File.basename(uri.to_s)), 'wb')
		  Net::HTTP.start(uri.host) do |http|
		  	target = uri.path
		  	target << ('?' + uri.query) if uri.query
		  	status = 0
		    http.request_get(target) do |res|
		    	# handle redirects
 			    return download_file(URI(res['location'])) if res.header['location']
		    	res.read_body { |segment| f.write(segment) }
		    	return res.code == "200"
		    end
  		end
 	  ensure 
 	  	f.close    	
 	  end
	end
	
	
end


a =	Archiver.new
CSV.foreach("found_master_tickets.csv", :headers => :first_row, :return_headers => false) do |row|
  name = row[1]
  version = row[2]  
  case 
  when row[6].include?('rubygems.org')
  	success = a.get_rubygem(name, version) 
  when row[6].include?('maven.org')  	
  	success = a.get_javasource(name, version) 
  when row[6].include?('npmjs.org')
  	success = a.get_node_package(name, version) 
  else
  	success = false
  end
  unless success
  	puts "=> problem downloading #{name} #{version}"
  end
end


