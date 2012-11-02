#!/usr/bin/env ruby
#
# This is Scotty
# A script for accessing VMware's software licensing platform (Scotzilla)
#
# Copyright 2012 © VMware, Inc.
#
# Authors: Matthew Reider (mreider@vmware.com)
#          Jim Apperly    (japperly@vmware.com)

$: << './lib'

require 'scotty'

Scotty::Scotty.start
