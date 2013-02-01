#
# scotty_config.rb
#

require 'yaml'
require 'errors'

module Scotty

  class Config
    include Errors

    FILE="#{Dir.home}/.scotty"

    def initialize(path=FILE)
      error(3) unless File.exists? path
      @yaml = nil
      File.open(path, 'r') { |f| @yaml = YAML::load(f.read) }
    end

    def sz_user
      @yaml['user']
    end

    def sz_pass
      @yaml['password']
    end

    def sz_host
      @yaml['host']
    end

    def sz_path
      @yaml['path']
    end

    def sz_port
      @yaml['port']
    end

    def sz_use_ssl?
      @yaml['use_ssl']
    end

    def name_version_mapper
      @yaml['name_ver_mapper']
    end

    def cf_version
      @yaml['product_version']
    end

    def mte_desc
      @yaml['description']
    end

    def license_text
      @yaml['license_text']
    end

    def license_name
      @yaml['license_name']
    end

    def psa_category
      @yaml['category']
    end

    def psa_desc
      @yaml['use_ticket_description']
    end

    def psa_interaction
      @yaml['interaction']
    end

    def psa_features
      @yaml['features']
    end

    def self.create
      return <<-EOF
        user:
        password:
        host: scotzilla.eng.vmware.com
        path: /xmlrpc.cgi
        port: 443
        use_ssl: true
        name_ver_mapper:
        license_text: UNKNOWN
        license_name: UNKNOWN
        category: VMWsource
        product_version:
        description: Automated ticket based on product scanning
        use_ticket_description: required functionality depends upon on this component
        interaction: ['Distributed - Calling Existing Classes']
        features:
      EOF
    end

  end

end

