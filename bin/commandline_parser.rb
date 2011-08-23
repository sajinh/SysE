require File.join(File.dirname(__FILE__), 'choice-0.1.2/lib/choice')

PROGRAM_VERSION = 1

Choice.options do
  banner "Usage: ctl2ncl.rb [options]"
  
  header "A grads ctl parser and NCL script generator based on ruby"
  header "Specific options:" 
  
  option :infile, :required => true do
    short '-i'
    long '--infile CTLFILE'
    desc "the grads ctl file "
    validate /\w+\.[cC][tT][lL]/
  end
  option :outfile, :required => true do
    short '-o'
    long '--outfile NCLFILE'
    desc "the NCL script file "
    validate /\w+\.ncl/
  end


  option :vars do
    short '-v'
    long '--vars *NUM'
    desc "variables to retrieve"
    desc "e.g: --vars u850 t850 prec"
    desc "or -v u850 t850 prec"
    default :all
  end

  option :times do
    short '-t'
    long '--time time(s)'
    desc "-t : supply time as indices"
    desc "e.g -t 1:5 retrieves data"
    desc "from t=1 to 5"
    desc ""
    desc "--time : supply calendar time"
    desc "e.g --time Jan2005:Dec2005"
    desc "retrieves data from "
    desc "time =Jan2005 to Dec2005"
    default :tall
  end


  
  option :plot do
    long '--plot'
    desc 'add code to display figures'
  end  
  
   separator ''
   separator 'Common options: '

  option :help do
    long '--help'
    desc 'Show this message'
  end

  option :version do
    long '--version'
    desc 'Show version'
    action do
      puts "#{$0} ctl parser and translator v#{PROGRAM_VERSION}"
      exit      
    end
  end
  
end
