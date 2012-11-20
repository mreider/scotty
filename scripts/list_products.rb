#!/usr/bin/env ruby
#
# list_products.rb
#
# Prints a list of CloudFoundry products that are registered with
# Scotzilla.
#

$: << '../lib/'

require 'scotty_config'
require 'nokogiri'
require 'optparse'

URL='https://scotzilla.eng.vmware.com/szsearch.cgi?type=tst'

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

c = Scotty::Config.new

v = options[:verbose]

puts "Downloading product list from Scotzilla..." if v
html = `curl -s -u #{c.sz_user}:#{c.sz_pass} "#{URL}"`

puts "Parsing list..." if v
doc = Nokogiri::HTML.parse(html)
doc.xpath("html/body/div[@id='bugzilla-body']/form//select[@id='vmprod']/option")
   .map { |o| o.text.strip }
   .select { |p| p.start_with? 'cf-' }
   .map { |p| options[:prefix] ? p[3..-1] : p }
   .sort { |a,b| a <=> b }
   .each { |p| puts p }

puts "Done." if v


