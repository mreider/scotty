#!/usr/bin/env ruby
#
# list_products.rb
#
# Prints a list of CloudFoundry products that are registered with
# Scotzilla.
#

require 'nokogiri'
require 'optparse'

URL='https://scotzilla.eng.vmware.com/szsearch.cgi?type=tst'

options = { :user => '' }
op = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} -u user:pass"
  opts.on("-u", "--user user:pass", "Provide username:password") { |u| options[:user] = u }
  opts.on("-v", "--verbose", "Verbose output") { |v| options[:verbose] = v }
  opts.on("-h", "--help", "Display this screen") { puts opts }
end

begin
  op.parse!

rescue => e
  puts e
  puts op
  exit 1
end

unless options[:user] =~ /^([^:]+):([^:]+)$/
  puts "invalid username:password"
  puts op
  exit 1
end


v = options[:verbose]

puts "Downloading product list from Scotzilla..." if v
html = `curl -s -u #{$1}:#{$2} "#{URL}"`

puts "Parsing list..." if v
doc = Nokogiri::HTML.parse(html)
doc.xpath("html/body/div[@id='bugzilla-body']/form//select[@id='vmprod']/option")
   .map { |o| o.text.strip }
   .select { |p| p.start_with? 'cf-' }
   .each { |p| puts p }

puts "Done." if v


