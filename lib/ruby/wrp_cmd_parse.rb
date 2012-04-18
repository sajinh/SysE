
require 'optparse'
require 'pp'


class Choice

def self.usage
  "Usage: wrap_all.rb [options]"
end

def self.choices
abort self.usage  if ARGV.empty?

options = {:compiler=> 'gfortran'}

OptionParser.new do |opts|

  opts.banner = usage
  opts.separator ""
  opts.separator "Specific options:"

  # Mandatory argument
  opts.on("-f", "--file f77[f90]", "the fortran source file") do |v|
    options[:infile] = v
  end

  opts.on("-c", "--com compiler", "which compiler should i use?") do |v|
    options[:compiler] = v
  end

  opts.on("--com_opts a,b,c", Array, "compiler options separated by space") do |v|
    options[:com_opts] = v
  end

end.parse!


abort self.usage unless (options[:infile])
return options
end
end
