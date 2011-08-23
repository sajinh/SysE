#!/usr/bin/env ruby

require 'yaml'
require File.join(File.dirname(__FILE__), 'highline_parser')
require File.join(File.dirname(__FILE__), 'grads_utilities')

opts=menu
ctl_to_ncl opts
