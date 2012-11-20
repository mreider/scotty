#!/usr/bin/env ruby
#
# search for use tickets by product
#

require 'nokogiri'

SEARCH_URL='https://scotzilla.eng.vmware.com/buglist.cgi?bug_status=ASSIGNED&bug_status=CLOSED&bug_status=ENG%20CONFIRM%20CT&bug_status=NEW&bug_status=PEND%20PATENT%20REVIEW&bug_status=PM%20CONFIRM%20CT&bug_status=REOPENED&bug_status=RESOLVED&bug_status=UNCONFIRMED&bug_status=VERIFIED&classification=Product%20Specific%20Approvals&columnlist=cf_osspkgname%2Ccf_osspkgvers%2Cassigned_to%2Cbug_status%2Cresolution%2Ccf_category%2Cproduct%2Cversion%2Ccf_mte_id&query_format=advanced&rep_platform=PSA&szsearch=1&query_based_on='

def sz_use_tickets_by_products(user_pass, *sz_product)
  exit 1 unless user_pass && user_pass.is_a?(String) && user_pass.split(':').size == 2
  exit 1 unless sz_product

  url = SEARCH_URL + "&product=#{sz_product.join('&product=')}&version=09%2F01%2F2012" # fixed version

  out = `curl -s -u #{user_pass} "#{url}"`

  buglist = Nokogiri::HTML.parse(out)

  bugs = buglist.xpath("/html/body//table[@class='bz_buglist']").flat_map do |table|
    table.xpath("tr[position() > 1]").map do |tr|
      { :id => tr.xpath('td[1]/a')[0].text.strip,
        :name => tr.xpath('td[2]')[0].text.strip,
        :version => tr.xpath('td[3]')[0].text.strip,
        :assignee => tr.xpath('td[4]/span')[0].text.strip,
        :status => tr.xpath('td[5]/span/@title')[0].text.strip,
        :resolution => tr.xpath('td[6]/span')[0].text.strip,
        :category => tr.xpath('td[7]')[0].text.strip,
        :cf_product => tr.xpath('td[8]/span')[0].text.strip,
        :cf_version => tr.xpath('td[9]/span').text.strip,
        :mte => tr.xpath('td[10]')[0].text.strip
      }
    end
  end

  bugs.each { |b| yield b } if block_given?
  bugs
end

if ARGV.size < 2
  puts "Usage: #{$0} user:pass sz_prod [ sz_prod ... ]"
  exit 1
end

sz_use_tickets_by_products(ARGV.shift, ARGV) do |b|
  puts "#{b[:id]} #{b[:name]} #{b[:version]} #{b[:assignee]} #{b[:status]} #{b[:resolution]} #{b[:category]} #{b[:cf_product]} #{b[:cf_version]} #{b[:mte]}"
end


