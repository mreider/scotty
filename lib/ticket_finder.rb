#!/usr/env/ruby
# Copyright 2012 © VMware, Inc.

require 'girl_friday'
require 'sz_api'

module Scotty

  # Encapsulates the process of looking up Scotzilla
  # tickets using a set of background processes
  #
  class TicketFinder

    class ErrorHandler
      def handle(ex)
        begin
          GirlFriday::ErrorHandler::Stderr.new.handle(ex)
          GirlFriday.shutdown!(0)
        ensure
          exit 1
        end
      end
    end

    # init with Scotzilla host and credentials
    def initialize


      # work queue for master tickets
      @master = GirlFriday::Batch.new(nil, :size => 10, :error_handler => ErrorHandler) do |component|
        puts "TicketFinder: finding master ticket for #{component.name} #{component.version}"
        scotzilla = SZ_API.from_config(::Scotty::CONF)
        component.result = scotzilla.find_master_ticket(component.sz_args)
        component
      end

      # work queue for use tickets
      @use = GirlFriday::Batch.new(nil, :size => 10, :error_handler => ErrorHandler) do |args|
        puts "TicketFinder: finding use ticket for #{args}"
        scotzilla = SZ_API.from_config(::Scotty::CONF)
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

end
