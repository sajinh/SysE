#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '../lib/ruby', 'wrp_cmd_parse.rb')
require File.join(File.dirname(__FILE__), '../lib/ruby', 'wrapit.rb')

opts = Choice.choices


cmd=$0
fname=opts[:infile]
options=opts[:com_opts]
compiler=opts[:compiler] || "gfortran"
unless options==nil
  options.map! {|o| " -"+o}
else
  options=""
end

puts (" Execute #{cmd} --comp #{compiler} #{options} --file #{fname}")

wrapit(fname,compiler,options)
