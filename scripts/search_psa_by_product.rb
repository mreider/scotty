#!/usr/bin/env ruby
#
# search_psa_by_product.rb
#
# Search Scotzilla for use tickets (PSA) by product
#

$: << '../lib/'

require 'sz_api'

if ARGV.size == 0
  puts "Usage: #{$0} sz_prod [ sz_prod ... ]"
  exit 1
end

Scotty::SZ_API.find_all_use_tickets_by_product('09/01/2012', ARGV).each do |b|
  puts "#{b[:id]} #{b[:name]} #{b[:version]} #{b[:assignee]} #{b[:status]} #{b[:resolution]} #{b[:category]} #{b[:cf_product]} #{b[:cf_version]} #{b[:mte]}"
end


