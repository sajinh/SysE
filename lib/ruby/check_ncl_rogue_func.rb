require 'pp'
class NCLParser
  def initialize(infil,write_all=false)
    @fin=File.open(infil,'r')
    @fpath=File.dirname(infil)
    @fout=File.open(File.join(
              @fpath,File.basename(infil,".ncl")+"_modified.ncl"),"w")
    @write_all=write_all
    @found_rogue_func=false
    @rog_fun=0
  end

  def write_out?()
   return(true) if @write_all | @found_rogue_func
   false
  end

  def insert_line(where,identifier,section,line,comment="")
    if identifier==:current
      idx=section[:code].length 
    else
      found=section[:code].select {|str| str =~ /^\s*#{identifier}/}
      idx=section[:code].index(found[0])
    end
    where==:after ? idx+=1 : idx-=1
    spacer=(section[:code][idx])[/^\A\s*/].length
    comment="\s"*spacer+";"+comment+"\n"
    section[:code][idx] = comment+"\s"*spacer+line+"\n"+section[:code][idx]
  end

  def initialize_hash
    {:code => [], :rog_arg => []}
  end

  def parse
    section=initialize_hash
    @fin.each do  |line|

      section[:code] << line
      case line
      when /((function|procedure)\b)(\s+\w+)(\()(\w+(,\s*\w+)*)/
        section[:type],section[:name]=$1,$3
        section[:args]=$5.split(",")
        next
      when /^\s*return\s*\(/
        comment="copying back function argument from temporary variable"
        section[:rog_arg].uniq! # remove duplicates
        section[:rog_arg].each do |arg| 

          if @found_rogue_func
            insert_line(:before,:current,section, "#{arg}=__#{arg}",comment)
          end
        end
        next
      when /^\s*end\W+$/
        write_out(section) if write_out?
        section=initialize_hash
        @found_rogue_func = false       
        next
      end
      
      case k=section[:type]
      when /function/
        comment="copying function argument to temporary variable"
        section[:args].each do |arg| 
          if line[/^\s*#{arg}\s*=/]
            @found_rogue_func=true
            break if section[:rog_arg].any? {|aa| aa == arg}
            insert_line(:after,"begin",section,"__#{arg}=#{arg}",comment)
            section[:rog_arg] << arg
          end 
        end
      end
    end
    clean_up
  end
  def write_out(data)
    fn_name=data[:name] 
    @fout.puts "load \"#{@fin.path}\"" if @rog_fun == 0
    @fout.puts "undef(\"#{fn_name}\")"
    @fout.puts data[:code]
    @rog_fun+=1
  end
  def clean_up
    p "Rogue function detected in #{@fin.path}" unless @rog_fun == 0
    @fout.close 
    File.unlink(@fout.path) if @rog_fun == 0
  end
end
