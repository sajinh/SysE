#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__),'ctl_cmd_parse.rb')
require File.join(File.dirname(__FILE__), 'grads_utilities')

ctl_to_ncl  Choice.choices

#begin
#  require File.join(File.dirname(__FILE__), 'ctl2ncl_a.rb')
#rescue
   p $!
#  require File.join(File.dirname(__FILE__), 'ctl2ncl_c.rb')
#end
