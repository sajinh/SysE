
FORTRAN_COMPILER="gfortran"

SysE=ENV['SysE']
NCL_Libs=File.join SysE, 'lib/ncl'
SRC_DIRS=FileList["data_analysis","readers", "writers", "ccsm"]
COMPILER_OPTS=nil

require File.join SysE, "lib/ruby/wrapit"


tasks=SRC_DIRS.map do |d| 

  src_dir=File.join NCL_Libs, d, "fortran/source"
  Dir.chdir(src_dir) do

   
    Dir.glob("*.f*").map do |f| 
      tnm=f.sub(File.extname(f),"")
     "#{d}:#{tnm}"
    end
  end
end

desc "Runs the default tasks"
task :default => tasks.flatten

task :clean do
  puts "Cleaning up"
  tasks.each do |subtask|
    subtask.each do |tsk|
     dir,obj=tsk.split(":")
     dir=File.join NCL_Libs,dir,"fortran/shared"
     obj=File.join dir,"#{obj}.so"
     begin
       rm obj
     rescue
       puts "No such file #{obj}"
     end
    end
  end
end

SRC_DIRS.each do |dir|
  name=File.basename dir

  namespace name.to_sym do

    src_dir=File.join NCL_Libs, name, "fortran/source"
    obj_dir=File.join NCL_Libs, name, "fortran/shared"
    sources=Dir.glob("#{src_dir}/*.f*")
    sources.each do |src|

      srcnm=File.basename(src)
      ext=File.extname(src)
      task_nm=srcnm.sub(ext,"")
      file_nm=task_nm+".so"
      file_nm=File.join(obj_dir,file_nm)

      file file_nm => src do |t|
        Dir.chdir(obj_dir) do
          puts "Creating #{file_nm}"
          wrapit(src,FORTRAN_COMPILER,COMPILER_OPTS)
        end
      end
      task task_nm.to_sym => file_nm
    end
    namespace :clean do

      objects=Dir.glob("#{obj_dir}/*.so")
      task :all do

        objects.each {|obj| "Removing #{obj}"; rm obj}
      end
      objects.each do |obj|

        onm = File.basename(obj) 
        task onm.to_sym do
          rm obj
        end
      end
    end
  end
end

