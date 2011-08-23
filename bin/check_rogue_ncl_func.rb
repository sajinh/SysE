#! /bin/env ruby
require 'pathname'
require File.join(File.dirname(__FILE__),'rogue_ncl_func')

def usage()
  fn_name = File.basename($0)
  puts fn_name+" dir1 dir2 dir3 "
  spacer="   "+"---"*((fn_name.length/3)-6)+"> "
  puts spacer+"   dir1 dir2 ... etc specifies "
  puts spacer+"   directories containing ncl files(libraries) "
  exit
end
usage  if ARGV.empty?

ARGV.each do |root_dir|
  Pathname.glob("#{root_dir}/*.ncl") do |infil|
    NCLParser.new(infil).parse if File.exist? infil
  end
end

