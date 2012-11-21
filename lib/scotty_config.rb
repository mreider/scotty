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
      system('wget -O ~/.scotty http://vmcpush.com/scotty.txt -q')
    end

  end

end

