#!/usr/bin/env ruby

$: << '../lib'

require 'scotty'
require 'sz_api'

if ARGV.size != 2
  puts "Usage: #{$0} <name> <version>"
  exit 1
end

config = ::Scotty.config
sz = Scotty::SZ_API.new(config['host'], "/" + config['path'], config['port'],
                        config['use_ssl'], config['user'], config['password'])

name = ARGV[0]
version = ARGV[1]

result = sz.find_master_ticket({ :name => name,
                                 :version=>version,
                                 :category=>'VMWsource'})

puts result


