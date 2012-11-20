#!/usr/bin/env ruby
#
# search_mte.rb
#
# Search Scotzilla for master ticket entries.
#

$: << '../lib'

require 'scotty_config'
require 'sz_api'

if ARGV.size != 2
  puts "Usage: #{$0} <name> <version>"
  exit 1
end

sz = Scotty::SZ_API.from_config(Scotty::Config.new)

name = ARGV[0]
version = ARGV[1]

result = sz.find_master_ticket({ :name => name,
                                 :version=>version,
                                 :category=>'VMWsource'})

puts result


