Scotty README
-------------

Scotty is a script for accessing Scotzilla

Copyright 2012 - 2013 © VMware

Author: Matthew Reider at VMware
        James Apperly at VMware

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

8. Also change the product_version in ~/.scotty to the next release version. As of Q3 2012 we are using dates for versions. The first was 09/01/2012. It's a good idea to date the version about three weeks in the future from when you file tickets as this is likely when legal will catch up and issue license files.

9. Make sure you have a subdirectory named 'software' under the directory where scotty.rb exists.

1. Download / clone all of the Cloud Foundry bits to this directory with

    curl -s "https://api.github.com/orgs/cloudfoundry/repos?per_page=100" | ruby -rjson -e 'JSON.load(STDIN.read).each {|repo| %x[git clone #{repo["ssh_url"]} ]}'


Scotty parses Ruby, Node, and Maven (Java) apps using the following files to get component and version lists:

- Gemfile.lock
- package.json
- pom.xml

Scotty also assumes that all of the directories (Github repositories) in /software map to a product name in Scotzilla. The current list of these repository / product names are:

- ACM
- BOSH
- BOSH Release
- BOSH Sample Release
- Caldecott
- CF
- CF Docs
- CF Plugin
- CF-Release
- Cloud Controller
- Cloud Controller NG
- Common
- DEA
- Gonats
- Gonit
- Gosigar
- Health Manager
- Membrane
- Micro
- Micro Deployments
- OSS Bits
- OSS Tools
- Package Cache
- Router
- Stager
- UAA
- vBlob
- VCAP
- VCAP Java
- VCAP Concurrency
- VCAP Java Client
- VCAP Node
- VCAP Services Base
- VCAP Staging
- VCAP Test Assets
- VCAP Tools
- VCAP Yeti
- VMC
- VMC Giue
- VMC Lib
- Warden

Note: Please update this list if you add a new product to Scotzilla.

Double Note: The name of these products in Scotzilla is alwyas preceded by a 'cf' - (for instance cf-Micro, or cf-CF-Release)

# Creating Scotzilla tickets for Cloud Foundry

1. Open your ~/.scotty file and make sure the product_version is correct. You should file bugzilla tickets for new versions for each of the repos before continuing.

1. Scan the repository

    ruby scotty.rb scan

1. After scanning for master tickets generates: `found_master_tickets.csv` and `missing_master_tickets.csv`

1. Review `missing_master_tickets.csv` file and look for malformed rows / records.

1. If `missing_master_tickets.csv` is well formed, go ahead and file tickets using:

    ruby scotty.rb create

1. Scan your repository again. `missing_master_tickets.csv` should be empty now. If it isn't file an issue here on Github, as there is a bug.

1. Now that you have created all of your master tickets, it's time to scan for Use Tickets.

    ruby scotty.rb -r use

1. After scanning for use tickets the following will be generated: `found_use_tickets.csv` and `missing_use_tickets.csv`

1. Review `missing_use_tickets.csv` and look for malformed rows / records.

1. If `missing_use_tickets.csv` is well formed, go ahead and file use tickets using:

    ruby scotty.rb create -r use

1. Scan for use tickets again. `missing_use_tickets.csv` should be empty now. If it isn't - file an issue here on Github, as there is a bug.

Thanks for using Scotty!
