# Encapsulate the Scotzilla API
# Copyright VMware Inc. 2012
#

class SZ_API

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

  def find_use_ticket(args)
    call("SCOTzilla.find_requests", args)
  end
  
  private
  
  def call(method, args)
  	begin
     @server.call(method, args)
   
   rescue => e
   	 puts "Error calling #{method} with #{args}"
     if e =~ /SocketError/
       error(2)
     else
       puts e
       error(0)
     end
   end
   
  end
  
end
