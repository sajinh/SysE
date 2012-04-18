
require 'optparse'
require 'pp'


class Choice

def self.usage
  "Usage: ctl2ncl.rb [options]"
end

def self.choices
abort self.usage  if ARGV.empty?

options = {:times=>:tall,:vars=>:all, :plot=>false}

OptionParser.new do |opts|

  opts.banner = usage
  opts.separator ""
  opts.separator "Specific options:"

  # Mandatory argument
  opts.on("-i", "--infile CTLFILE", "the grads ctl file") do |v|
    options[:infile] = v
  end
  opts.on("-o", "--outfile NCLFILE", "the output NCL script") do |v|
    options[:outfile] = v
  end

  opts.on("-v", "--vars *NUM", "the variables to retrieve") do |v|
    options[:vars] = v.split(",")
  end

  opts.on("-t", "--time time(s)", "supply time as indices",
                    "e.g -t 1:5 ",
                    'alternatively --time Jan2005:Dec2005') do |v|
    options[:times]=v
  end
  opts.on("-p", "--plot", "add code to display figures") { options[:plot] = true}


end.parse!


abort self.usage unless (options[:infile] and options[:outfile])
return options
end
end
