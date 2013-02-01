# Custom mapping scheme for Cloudfoundry
#
module Scotty

  class Mapper
    class << self
      def map_repo_to_sz_name_ver(repo_name)
        return 'cf-' + repo_name, '09012012'
      end
    end
  end
end
