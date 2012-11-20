# Encapsulate the Scotzilla API
# Copyright 2012 © VMware, Inc.
#

require 'xmlrpc/client'

module Scotty

  class SZ_API
    include Errors

    def initialize(host, path, port, use_ssl, user, password)
      @server = XMLRPC::Client.new(host, path, port, nil, nil, user, password, use_ssl, nil)
      @counter = 0
    end

    def create_master_ticket(args)
      call("SCOTzilla.create_master", args)
    end

    def create_use_ticket(args)
      call("SCOTzilla.create_request", args)
    end

    def find_master_ticket(args)
      call("SCOTzilla.find_master", args)
    end

    # args = { product:name, version:ver, mte:id }
    def find_use_ticket(args)
      call("SCOTzilla.find_requests", args)
    end

    def self.from_config(config)
      c = config
      SZ_API.new(c.sz_host, c.sz_path, c.sz_port, c.sz_use_ssl?, c.sz_user, c.sz_pass)
    end

    private

    def call(method, args)
      begin
        @counter += 1
        @server.call_async(method, args)

      rescue => e
        puts e
        puts e.backtrace
        puts "Error calling #{method} with #{args} on req #{@counter}"
        if e =~ /SocketError/
          error(2)
        else
          error(0)
        end

        # Connection reset by peer
      end

    end
  end
end
