Scotty README
-------------

Scotty is a script for accessing Scotzilla

Copyright 2012 © VMware

Author: Matthew Reider at VMware

# Prerequisites

1. Install Ruby using RVM

		curl -L get.rvm.io | bash -s stable

2. Load RVM

		source ~/.rvm/scripts/rvm
			
3. Install Ruby 1.9.3
		
		rvm install 1.9.3
		
4. Set this Ruby as your default

		rvm use 1.9.3 --default
		
5. Install bundler

		gem install bundler

6. Unzip Scotty somewhere, open a command prompt in that directory
7. Run bundler

		bundle install
		
8. Run Scotty

		ruby scotty.rb [arguments]
		
6. If you don't have a .scotty file in your home directory, Scotty will create one
7. Edit your ~/.scotty file with your VMware username and password

Scotty parses Ruby, Node, and Maven (Java) apps using the following files to get component and version lists:

- Gemfile.lock
- package.json
- pom.xml

# Scanning your software repository

1. Make sure you have a directory named 'software' in your current directory or use the -d option.
1. Download / clone all of the Cloud Foundry bits to this directory with
  curl -s "https://api.github.com/orgs/cloudfoundry/repos?per_page=100" | ruby -rjson -e 'JSON.load(STDIN.read).each {|repo| %x[git clone #{repo["ssh_url"]} ]}'
1. Scan the repository

		ruby scotty.rb scan
		
1. After scanning for master tickets generates: `found_master_tickets.csv` and `missing_master_tickets.csv`
1. After scanning for use tickets (based on master sheets) generates: `found_use_tickets.csv` and `missing_use_tickets.csv`

## Options

### gpl
To Check the repository for GPL license and quits with the GPL license location printed to stdout

	ruby scotty.rb scan -gpl

### Type
Set the type of a search with '-t' (currently supports 'node', 'maven', or 'ruby')

	ruby scotty.rb scan -t maven

### Target Directory
Set the directory to scan with '-d'

	ruby scotty.rb scan -d ~/software/myapp

### Request Type
Set the request type to scan using -r (currently supports 'master' or 'use')

	ruby scotty.rb scan -r master

# The Entire flow of Creating new tickets

1. Make sure you have run scans for both master and use tickets
1. Open the `missing_master_tickets.csv` file and check it so that tickets can be created accurately.
1. Create Master tickets

		ruby scotty.rb create -r master
		
1. After creating master tickets, a new scan will be run, and new spreadsheets will be generated
1. Make sure that `missing_master_tickets.csv` is empty. If not - there's a bug! (report it)
1. Scan for use tickets

		ruby scotty.rb scan -r use

1. The file `missing_use_tickets.csv` will be created (as well as `found_use_tickets`, but this is informational / not parsed by scotty)
1. Create Use tickets (this parses `missing_use_tickets.csv` and creates new ones based on the interaction and features set in ~/.scotty)

		ruby scotty.rb create -r use
		
1. After creating use tickets, a new scan will be run, and new `missing_use_tickets.csv` will be created
1. Make sure that `missing_use_tickets.csv` is empty. If not - there's a bug! (report it)

Thanks for using Scotty.