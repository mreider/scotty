#!/usr/bin/env ruby
#
# list_products.rb
#
# Prints a list of CloudFoundry products that are registered with
# Scotzilla.
#

$: << '../lib/'

require 'sz_api'
require 'nokogiri'
require 'optparse'

options = {}
op = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [ options ]"
  opts.on("-v", "--verbose", "Verbose output") { |v| options[:verbose] = v }
  opts.on("-p", "--prefix", "Strip 'cf-' prefix from product names") { |p| options[:prefix] = p }
  opts.on("-h", "--help", "Display this screen") { puts opts }
end

begin
  op.parse!

rescue => e
  puts e
  puts op
  exit 1
end

v = options[:verbose]

Scotty::SZ_API.get_product_list(options[:prefix]) { |s| puts s if v }.each { |p| puts p }

puts "Done." if v


