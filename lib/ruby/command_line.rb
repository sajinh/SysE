#require File.join(File.dirname(__FILE__), 'choice-0.1.2/lib/choice')
require 'rubygems'
require 'choice'

Choice.options do
  banner "Usage: wrap_all.rb [options]"

  header "wrapper script to generate shareable fortran objects for use with NCL"
  header "Specific options:"

  option :infile, :required => true do
    short '-f'
    long '--file f77[f90]'
    desc "f77 or f90 files"
  end
  option :compiler do
    short '-c'
    long '--com'
    desc "which compiler "
    desc "default is  gfortran "
    desc "to use pgf, say -c pgf"
  end
  option :options do
    short '-o'
    long '--com_opts *ComOpts'
    desc "compiler options separated by space"
  end
end
