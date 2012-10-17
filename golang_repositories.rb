#!/usr/bin/env ruby
#

class GolangRepositories
  
  # modified from http://golang.org/src/cmd/go/vcs.go
  @@vcsPaths = { 
     # Google Code - new syntax
     "code.google.com" => { :vcs => 'hg', :repo => 'https://', name=>'google code' },
     # Google Code - old syntax
     ".googlecode.com" => { :vcs => 'hg', :repo => 'https://', name=>'old google code' },
     # Github
     "github.com" => { :vcs => 'git', :repo => 'https://', name=>'github', :vcssuffix => true },
     # Bitbucket
     "bitbucket.org" => { :repo => 'https://', name=>'bitbucket'},
     # Launchpad
     "launchpad.net" => { :vcs => 'bzr', :repo => 'https://', name=>'launchpad' }
  }
  
  def self.map_download_url(import_path)
    prefix = import_path.include?('/') ? import_path[0, import_path.index('/')] : import_path
    if vcs = @@vcsPaths[prefix]
    	return vcs[:repo] + import_path + (vcs[:vcssuffix] ? '.' + vcs[:vcs] : '') 
    end
   	return nil
  end

end

