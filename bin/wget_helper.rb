#!/usr/bin/env ruby

loop do
 fnam=gets.chomp
 exit if fnam=='x'
 exit if fnam.empty?
 `wget #{fnam}`
end
