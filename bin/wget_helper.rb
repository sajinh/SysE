#!/usr/bin/env ruby

loop do
 puts "Enter 'x' to exit"
 fnam=gets.chomp
 exit if fnam=='x'
 exit if fnam.empty?
 `wget #{fnam}`
end
