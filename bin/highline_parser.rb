require File.join(File.dirname(__FILE__),'highline-1.4.0/lib/', 'highline/import')

def menu
  say "This is an alternative version of the program"
  say "Please input the following"
  
  opts = Hash.new
  opts[:infile] = ask("Input File? ") { |q| q.validate =  /\w+\.[cC][tT][lL]/ }
  opts[:outfile] = ask("Output File? ") { |q| q.validate = /\w+\.ncl/ }
  opts[:vars] = ask("List of variables? Press enter to choose all variables ") do  |q| q.default = "all" 
 end
  opts[:vars]=:all if opts[:vars]=="all"
  opts[:times]=:tall
  return opts
end
