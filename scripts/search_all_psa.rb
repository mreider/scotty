#!/usr/bin/env ruby
#
#,search_psa_by_product.rb
#
#,Search Scotzilla for use tickets (PSA) by product
#

$: << '../lib/'

require 'sz_api'

# TODO: cf_product (and possibly cf_version) are truncated; find out why



Scotty::SZ_API.find_all_use_tickets('09/01/2012').each do |b|
  puts Scotty::SZ_API.use_ticket_query_columns.map { |col| b[col] }.join(',')
end


