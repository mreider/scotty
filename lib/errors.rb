#
# Errors
#
# Copyright 2012 © VMware, Inc.

module Scotty; end
module Scotty::Errors

  def error(code, *args)
    case code
      when 0
        puts "[ERROR] An uknown error occurred"
      when 1
        puts "[ERROR] No package file found in " + (args || []).join
        puts "[ERROR] for Maven there must be a pom.xml (and mvn installed)"
        puts "[ERROR] for Node there must be a package.json"
        puts "[ERROR] for Ruby there must be a Gemfile.lock (run bundler)"
      when 2
        puts "[ERROR] A SocketError occurred. Make sure you have a VPN connection if you are not on the VMware network"
      when 3
        puts "[ERROR] A scotty config file could not be found"
        puts "[INFO]  A config file was written to ~/.scotty"
      when 5
        puts "[ERROR] Cannot find " + (args || []).join
      when 7
        puts "[ERROR] Invalid ticket_type - values can be either 'master' or 'use'"
    end
    puts "\n\n"
    exit
  end

  module_function :error

end
