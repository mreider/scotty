#!/usr/env/ruby
# Copyright 2012 © VMware

require 'girl_friday'
require_relative 'sz_api'

# Encapsulates the process of looking up Scotzilla
# tickets using a set of background processes
#
class TicketFinder
	
	# init with Scotzilla host and credentials
	def initialize(host, path, port, use_ssl, user, password)

	  # work queue for master tickets
		@master = GirlFriday::Batch.new(nil, :size => 10) do |component|
			puts "TicketFinder: finding master ticket for #{component.name} #{component.version}"
			scotzilla = SZ_API.new(host, path, port, use_ssl, user, password)
			component.result = scotzilla.find_master_ticket(component.sz_args)
			component
		end
		
    # work queue for use tickets
		@use = GirlFriday::Batch.new(nil, :size => 10) do |args|
			puts "TicketFinder: finding use ticket for #{args}"
			scotzilla = SZ_API.new(host, path, port, use_ssl, user, password)
			scotzilla.find_use_ticket(args)
		end
	end
		
	def find_master(component)
		@master << component
	end
	
	def find_use(args)
		@use << args
	end
	
	def master_results
		# blocks until complete
		@master.results
	end
		
  def use_results
  	# blocks until complete
  	@use.results
  end
  
end
