#!/usr/bin/env ruby
#
# repos.rb
#
# Script for interacting with github.com/cloudfoundry
#

require 'optparse'
require 'json'

START_DIR=Dir.pwd
at_exit { Dir.chdir(START_DIR) }

def list_local
  Dir['*'].sort { |a,b| a <=>b }
          .each { |d| puts d }
end

def list_remote
  github_repos.map { |r| r['name'] }
              .sort { |a,b| a <=>b }
              .each { |d| puts d }
end

def list_missing
  locals = Dir['*']
  github_repos.reject { |r| locals.include? r['name'] }
              .map { |r| r['name'] }
              .sort { |a,b| a <=> b }
              .each { |d| puts d }
end

def clone_and_update_all
  clone_missing
  update_existing
end

def clone_missing
  locals = Dir['*']
  repos = github_repos.reject { |r| locals.include? r['name'] }.each do |r|
    puts "~> cloning #{r['name']}"
    `git clone #{r['ssh_url']}`
  end

end

def update_existing
  locals = Dir['*'].sort { |a,b| a <=>b }.each do |d|
    puts "~> updating #{d}"
    Dir.chdir(d) { `git pull` }
  end
end

def list_revs
  Dir['*'].sort { |a,b| a <=> b }.map do |d|
    next if Dir[d + '/.git/refs/heads/*'].empty?
    r = `cd #{d}; git rev-parse HEAD; cd ..`.chomp
    puts "#{d},#{r}"
  end
end

private

def path_to_software_dir
  return 'software' if Dir.exists? './software'
  case File.basename(Dir.pwd)
    when 'software'
      return '.'
    when 'scripts'
      return '../software'
  end
  raise "Cannot locate 'software' directory"
end

def github_repos
  JSON.parse(`curl -s "https://api.github.com/orgs/cloudfoundry/repos?per_page=100"`)
end

def print_usage
  opts = {
          :list_local => "Lists local repositories",
          :list_remote => "Lists repositories on github.com/cloudfoundry",
          :list_github => "Synonym for list_remote",
          :list_missing => "Lists remote repositories not cloned locally",
          :clone => "Clone remote repositories to local machine",
          :update => "Updates all local repositories to remote head (does not clone anything missing)",
          :update_all => "Updates all local repositories to remote head and clones any missing repositories",
          :list_revs => "",
          :help => "Prints this message"
  }

  s = "Usage: #{$0} [option]\r\n"
  opts.each_pair do |k,v|
    s << "\t#{k.to_s}\t\t#{v}\r\n"
  end
  puts s
end

#===================================#

Dir.chdir(path_to_software_dir)

if ARGV.size == 0
  list_local
  exit 0
end

case ARGV[0]
when 'list_local' then list_local
when 'list_remote','list_github' then list_remote
when 'list_missing' then list_missing
when 'clone' then clone_missing
when 'update' then update_exisiting
when 'update_all' then clone_and_update_all
when 'list_revs' then list_revs
when 'help' then print_usage
else
  puts "invalid option: #{ARGV[0]}"
  print_usage
  exit 1
end

exit 0


