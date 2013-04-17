# Copyright (c) VMware 2013
#
module Scotty

  class Mapper

    class << self

      def default_sz_ver(repo_name)
        return repo_name, '1.0.0'
      end

      # redefine this method to implement
      # custom mapping schemes
      #
      def map_repo_to_sz_name_ver(repo_name)
        return default_sz_ver(repo_name)
      end

    end

  end

end
