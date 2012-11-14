#!/usr/bin/env ruby
#
# search_contrib.rb
#

require 'thor'
require 'nokogiri'

class SearchContrib < Thor

  SEARCH_URL = 'https://scotzilla.eng.vmware.com/buglist.cgi?cf_license=&classification=Open%20Source%20Contribution&columnlist=cf_osc_name%2Ccf_osc_version%2Cresolution%2Cshort_desc%2Creporter&field0-0-0=cf_osc_name&field0-1-0=cf_osc_version&field0-2-0=cf_osc_project&priority=&query_format=advanced&rep_platform=OSC&szsearch=1&type0-0-0=substring&type0-1-0=substring&type0-2-0=substring&value0-0-0=&value0-1-0=&value0-2-0=&query_based_on='.freeze

  def initialize
    super
  end

  desc "search", "Search Scotzilla for contribution requests"
  method_option :user, :aliases => "-u", :type => :string, :desc => "<user:password>", :required => true
  method_option :name, :aliases => "-n", :type => :string, :desc => "Search for a contribution by name"
  method_option :version, :aliases => "-v", :type => :string, :desc => "Search for a contribution by version"
  method_option :reporter, :aliases => "-r", :type => :string,:desc => "Search for a contribution by reporter"

  def search
    query = { :name => options.name,
              :version => options.version,
              :reporter => options.reporter }

    result = SearchContrib.search(query, *options.user.split(':'))

    unless result.size == 0
      # header row
      puts result[0].keys.join(',')
      # data
      result.map { |bug| bug.values.join(',') }.each { |bug| puts bug }
    end
  end

  def self.search(query, user, pass)
    # get all contributions
    bugs = buglist(user, pass)

    # filter
    bugs = bugs.select { |b| b[:name] =~ /#{query[:name]}/ } if query.include? :name
    bugs = bugs.select { |b| b[:version] =~ /#{query[:version]}/ } if query.include? :version
    bugs = bugs.select { |b| b[:reporter] =~ /#{query[:reporter]}/ } if query.include? :reporter

    # retval
    bugs
  end

  def self.buglist(user, pass)
    # download the buglist
    out = `curl -s -u #{user}:#{pass} "#{SEARCH_URL}"`

    # parse buglist
    bugs = []
    buglist = Nokogiri::HTML.parse(out)
    buglist.xpath("/html/body//table[@class='bz_buglist']/tr[position() > 1]").each do |tr|
      bug_data = { :id => tr.xpath('td[1]/a')[0].text.strip,
                   :name => tr.xpath('td[2]')[0].text.strip,
                   :version => tr.xpath('td[3]')[0].text.strip,
                   :status => tr.xpath('td[4]/span')[0].text.strip,
                   :desc => tr.xpath('td[5]')[0].text.strip,
                   :reporter => tr.xpath('td[6]/span')[0].text.strip }

      bugs << bug_data
    end

    # retval
    bugs
  end

end

SearchContrib.start



