##
# Encapsulate the Scotzilla API
# See: https://wiki.eng.vmware.com/Oss/API
#
# Copyright 2012 © VMware, Inc.
#

require 'xmlrpc/client'
require 'nokogiri'
require 'scotty_config'

module Scotty

  class SZ_API
    include Errors

    PSA_BY_PROD_URL='https://scotzilla.eng.vmware.com/buglist.cgi?bug_status=ASSIGNED&bug_status=CLOSED&bug_status=ENG%20CONFIRM%20CT&bug_status=NEW&bug_status=PEND%20PATENT%20REVIEW&bug_status=PM%20CONFIRM%20CT&bug_status=REOPENED&bug_status=RESOLVED&bug_status=UNCONFIRMED&bug_status=VERIFIED&classification=Product%20Specific%20Approvals&columnlist=cf_osspkgname%2Ccf_osspkgvers%2Cassigned_to%2Cbug_status%2Cresolution%2Ccf_category%2Cproduct%2Cversion%2Ccf_mte_id&query_format=advanced&rep_platform=PSA&szsearch=1&query_based_on='

    def initialize(host, path, port, use_ssl, user, password)
      @server = XMLRPC::Client.new(host, path, port, nil, nil, user, password, use_ssl, nil)
      @counter = 0
    end

    ##
    # See: https://wiki.eng.vmware.com/Oss/API#Creating_Master_Tickets
    #
    # Required args: name, version, license_text, license_name, source_url,
    #                category, username, password
    #
    # Options args: copyright_text, oss_project, src_location, encryption,
    #               disttype, bznum, intname, gb_target
    #
    # Returns:
    #   ok => { stat: 'ok', desc: '[Master Ticket] name - ver', id: 1234, type: 'MTE' }
    #  err => { stat: 'err', code: E123, data: [], mesg: 'failed' }
    #
    def create_master_ticket(args)
      add_credentials_if_missing(args)
      call("SCOTzilla.create_master", args)
    end

    ##
    # See: https://wiki.eng.vmware.com/Oss/API#Creating_Use_Request_Tickets
    #
    # Required args: mte, product, version, interatcionm description,
    #                username, password
    #
    # Optional args: modified, features
    #
    # Returns:
    #   ok => { stat: 'ok', desc: '[Product Specific Approval] name - ver : prod', id: 1234, type: 'PSA' }
    #  err => { stat: 'err', code: E123, data: [], mesg: 'failed' }
    #
    def create_use_ticket(args)
      add_credentials_if_missing(args)
      call("SCOTzilla.create_request", args)
    end

    ##
    # See: https://wiki.eng.vmware.com/Oss/API#Searching_for_Master_Tickets
    #
    # Required args: name, version, category
    #
    # Returns:
    #   ok => { stat: 'ok', desc: '[Master Ticket] name - ver', id: 1234, type: 'MTE' }
    #  err => { stat: 'err', code: E123, data: [], mesg: 'failed' }
    #
    # nb. only two errors possible E301 (not found) or E302 (multiple masters)
    #
    def find_master_ticket(args)
      call("SCOTzilla.find_master", args)
    end


    ##
    # See: https://wiki.eng.vmware.com/Oss/API#Searching_for_Use_Request_Tickets
    #
    # Required args: product, version, mte }
    #
    # Returns:
    #   ok => { stat: 'ok', mte: 1234, product: prod, version: ver, nrequests: 1,
    #           { desc: '[Product Specific Approval] name - ver : prod', id: 1234, type: 'PSA',
    #             assigned_to: '' reporter: '', legal_contact: '',
    #             license_name: '', eulap: '', osstarp: '',
    #             disttype: '', modified: '', src_location: '', feature: '', interations: '',
    #             + mte fields }
    #         }
    #
    def find_use_ticket(args)
      call("SCOTzilla.find_requests", args)
    end

    ##
    # Returns a list of CF products that are registered with Scotzilla
    #
    def self.get_product_list(strip_prefix=false)
      c = Scotty::Config.new
      yield 'Downloading product list from Scotzilla...' if block_given?
      html = `curl -s -u #{c.sz_user}:#{c.sz_pass} "https://scotzilla.eng.vmware.com/szsearch.cgi?type=tst"`
      yield 'Parsing list...' if block_given?
      doc = Nokogiri::HTML.parse(html)
      doc.xpath("html/body/div[@id='bugzilla-body']/form//select[@id='vmprod']/option")
        .map { |o| o.text.strip }
        .select { |s| s.start_with? 'cf-' }
        .map { |s| strip_prefix ? s[3..-1] : s }
        .sort { |a,b| a <=> b }
    end

    ##
    # Results a list of use tickets for the given version of
    # the supplied list of products
    #
    def self.find_all_use_tickets_by_product(version, *products)
      c = Scotty::Config.new
      url = PSA_BY_PROD_URL + "&product=#{products.join('&product=')}&version=#{version.gsub(/\//, '%2F')}"
      out = `curl -s -u #{c.sz_user}:#{c.sz_pass} "#{url}"`
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
            :cf_version => tr.xpath('td[9]/span')[0].text.strip,
            :mte => tr.xpath('td[10]')[0].text.strip
          }
        end
      end

      bugs
    end

    ##
    # Returns a list of all use tickets for a given CF version
    #
    def self.find_all_use_tickets(version)
      find_all_use_tickets_by_product(version, get_product_list)
    end

    ##
    # Create an instance of the API from a Scotty::Config
    #
    def self.from_config(config)
      c = config
      SZ_API.new(c.sz_host, c.sz_path, c.sz_port, c.sz_use_ssl?, c.sz_user, c.sz_pass)
    end

    private

    def add_credentials_if_missing(args)
      args[:username] = @server.user unless args[:username]
      args[:password] = @server.password unless args[:password]
    end

    def call(method, args)
      begin
        @counter += 1
        @server.call_async(method, args)

      rescue => e
        puts e
        puts e.backtrace
        puts "Error calling #{method} with #{args} on req #{@counter}"
        if e =~ /SocketError/
          error(2)
        else
          error(0)
        end

        # Connection reset by peer
      end

    end
  end
end
