#
# CodeComponent.rb
#
# Copyright 2012 © VMware, Inc.
#

module Scotty

  class CodeComponent
    attr_reader :name, :version, :subdir, :download_url
    attr_accessor :result

    def initialize(name, version, subdir, download_url)
      @name = name
      @version = version
      @subdir = subdir
      @download_url = download_url
      @key = nil
    end

    def category
      'VMWsource'
    end

    def id
      self.result['id'] if self.result
    end

    def key
      @key = [ sz_name, ':', sz_version ].join unless @key
      @key
    end

    def sz_name
      self.name.downcase
    end

    def sz_version
      self.version.downcase
    end

    def sz_args
      { :name => self.sz_name,
        :version => self.sz_version,
        :category => self.category }
    end

    def sz_product
      "cf-#{self.subdir}"
    end

    def language
      raise NotImplementedError
    end

    JAVA_LANG = :java
    NODE_LANG = :nodejs
    RUBY_LANG = :ruby
    GO_LANG = :golang

  end # CodeComponent

  module Language
  end

  class JavaComponent < CodeComponent
    def language
      JAVA_LANG
    end
  end

  class NodeComponent < CodeComponent
    def language
      NODE_LANG
    end
  end

  class RubyComponent < CodeComponent
    def language
      RUBY_LANG
    end
  end

  class GoComponent < CodeComponent
    def language
      GO_LANG
    end
  end

end
