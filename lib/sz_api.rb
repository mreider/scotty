# Encapsulate the Scotzilla API
# Copyright 2012 © VMware, Inc.
#

module Scotty

  class SZ_API
    include Errors

    def initialize(host, path, port, use_ssl, user, password)
      @server = XMLRPC::Client.new(host, path, port, nil, nil, user, password, use_ssl, nil)
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

    private

    def call(method, args)
      begin
        @server.call_async(method, args)

      rescue => e
        puts e
        puts e.backtrace
        puts "Error calling #{method} with #{args}"
        if e =~ /SocketError/
          error(2)
        else
          error(0)
        end
      end

    end
  end
end
