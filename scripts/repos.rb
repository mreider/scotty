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
              .sort { |a,b| a <=>b }
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
else puts "invalid option: #{ARGV[0]}"
end

exit 0


