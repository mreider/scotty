#
# scotty_ignore.rb
#

module Scotty

  class ScottyIgnore

    FILE = File.expand_path('scottyignore')

    def initialize
      raise "File not found: #{FILE}" unless File.exists? FILE
      @yaml = nil
      File.open(FILE, 'r') { |f| @yaml = YAML::load(f.read) }
    end

    def ignore_manifest?(path)
      @yaml['files'].each do |f|
        return f['reason'] if f['path'] == path
      end
      false
    end

    def ignore_component?(component)
      @yaml['components'].each do |c|
        # TODO: verify manifest path too once that gets added to component
        return c['reason'] if c['name'] == component.name and
                              c['version'] == component.version
      end
      false
    end

    private

  end

end

