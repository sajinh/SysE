require 'yaml'
require File.dirname(__FILE__)+"/./geo_coordinates"

def integer_value_of_month(month)
  months=%w(jan feb mar apr may jun jul aug sep oct nov dec)
  return months.index(month.downcase)+1
end

def terminateProgram
  puts "Program Terminated"
  puts " ........%< -----                  "
  puts "                   "
  exit
end

def parse_ctl_file
   infil=File.open(@ctlFile,"r")

   # modify the grads ctl file to make it
   # appear as a YAML formatted file
   data=""
   infil.each do |line|
    line.sub!(/^\w+\s/) { |s| s.downcase } # downcase keywords
    line.sub!(/^\*(.)*/,"empty word") # remove comments
    line.sub!(/^\#(.)*/,"empty word") # remove comments
    line.sub!("\n","\s\n") # add a space at end-of-line
    line.insert(line.index(/\s/),": ") if line.match(/^[a-z]+/)
    data = data+line if line.match(/\w+/)
   end
   data.gsub!(/\n+(?=[-]*[+]*\d+)/,"") # ah terrible grads ctl!

   modelHash  = YAML::load(data)
   @fileName  = modelHash['dset']
   @fillValue = modelHash['undef']
   @options   = (modelHash['options'] || "nothing").downcase
   @xdef      = modelHash['xdef']
   @ydef      = modelHash['ydef']
   @zdef      = modelHash['zdef']
   @tdef      = modelHash['tdef']
   @nvars     = modelHash['vars']

   # find the name of variables in the 'grads ctl' file
   # split "data" first at "vars:" and then at "endvars:"
   @var_table = data.split(/^vars:\s+\d+\s*/)[1].split(/^endvars:\s*/)[0]
end


def nclFileMessage
    puts "                   "
    puts " ........%< -----                  "
    puts "The NCL file exists"
    puts "Do either of the following and run the script again"
    puts "  1. Delete the current file (viz., #{@nclFile} ) OR rename it "
    puts "  2. Supply a new file name to write the NCL code  "
    terminateProgram
    puts " ........%< -----                  "
    puts "                   "
end

def ctlFileMessage
    puts "                   "
    puts " ........%< -----                  "
    puts "The grads control file does not exist"
    terminateProgram
    puts " ........%< -----                  "
    puts "                   "
end

def file_exists?(filename)
  File.exist?(filename)
end

def check_existence_of_files(opts)
  @ctlFile=opts[:infile]
  @nclFile=opts[:outfile]
  ctlFileMessage unless file_exists? opts[:infile]
  #nclFileMessage if file_exists? opts[:outfile]
end

def open_output_file
  @outfil=File.new(@nclFile,"w+")
  @outfil.puts "load \"$SysE/lib/ncl/helper_libs.ncl\"" if @debug
end

def cannot_handle_message
  puts "I cannot handle non-linear grids"
  terminateProgram
end

def parse_start_time(t1)
  tstring=t1
  tregxp=/\d+$/
  tyear=tstring.match(tregxp).to_s
  tstring.gsub!(tregxp,"")

  tregxp=/(\w\w\w)$/  # \w is not the best choice, but shortest
  tmonth=tstring.match(tregxp).to_s
  tstring.gsub!(tregxp,"")
  imonth=integer_value_of_month(tmonth)

  tregxp=/\d+$/
  tday="1"||tstring.match(tregxp).to_s
  tstring.gsub!(tregxp,"")

  tregxp=/\d\dZ$/
  tmin="0"||tstring.match(tregxp).to_s
  tstring.gsub!(tregxp,"")

  tregxp=/\d\d:$/
  thr="0"||tstring.match(tregxp).to_s
  tstring.gsub!(tregxp,"")

  return "#{tyear}-#{imonth}-#{tday} #{thr}:#{tmin}"
end

def parse_time_units(tint)
  tinc=tint.match(/^\d+/).to_s
  tunits=tint.match(/[a-z][a-z]$/).to_s
  
  time_units="years" if tunits=="yr"
  time_units="months" if tunits=="mo"
  time_units="days" if tunits=="dy"
  time_units="hours" if tunits=="hr"
  time_units="minutes" if tunits=="mn"
  return tinc.to_i,time_units
end

def create_tcoordinate
  tinfo = @tdef.split
  nt    = tinfo[0].to_i
  ttyp  = tinfo[1].downcase
  t1    = tinfo[2]
  tint  = tinfo[3]
  cannot_handle_message unless ttyp=="linear"
  start_time=parse_start_time(t1)
  tinc,tunits=parse_time_units(tint)
  t1    = 0.5
  t2    = t1 + (nt-1)*tinc
  @ntim = nt
  time="fspan(#{t1},#{t2},#{@ntim})"
  time="#{t1}" if @ntim==1
tdesc=<<EOF

; T co-ordinate
; ................
  ntim=#{@ntim}
  time=fspan(#{t1},#{t2},ntim)
  time!0="time"
  time&time=time
  time@units="#{tunits} since #{start_time}"
  time@long_name="time"
  printVarSummary(time)
EOF
end

def create_zcoordinate
  zinfo = @zdef.split
  nz    = zinfo[0].to_i
  ztyp  = zinfo[1].downcase
  z1    = zinfo[2].to_f
  zint  = zinfo[3].to_f
  z2    = z1 + (nz-1)*zint
  @nlev = nz
zdesc=<<EOF

; Z co-ordinate
; ................
  nlev=#{@nlev}
  #{Lev.new.main(@zdef)}
  lev!0="lev"
  lev&lev=lev
  lev@units="m" ; this is for GrADs
  lev@long_name="z-levels"
  lev@original_units = "unknown ... please fill in"
  printVarSummary(lev)
EOF
end

def create_ycoordinate
  yinfo = @ydef.split
  ny    = yinfo[0].to_i
  ytyp  = yinfo[1].downcase
  y1    = yinfo[2].to_f
  yint  = yinfo[3].to_f
  y2    = y1 + (ny-1)*yint
  @nlat=ny
  yord  = 1
  yord  = -1  if @options.match("yrev")
ydesc=<<EOF

; Latitude co-ordinate
; ................
  nlat=#{@nlat}
  #{Lat.new.main(@ydef)}
  lat=lat(::#{yord})
  lat!0="lat"
  lat&lat=lat
  lat@units="degrees_north"
  lat@long_name="Latitude"
  printVarSummary(lat)
EOF
end

def create_xcoordinate
  xinfo = @xdef.split
  nx    = xinfo[0].to_i
  xtyp  = xinfo[1].downcase
  x1    = xinfo[2].to_f
  xint  = xinfo[3].to_f
  x2    = x1 + (nx-1)*xint
  @nlon=nx
xdesc=<<EOF

; Longitude co-ordinate
; ................
  nlon=#{@nlon}
  #{Lon.new.main(@xdef)}
  lon!0="lon"
  lon&lon=lon
  lon@units="degrees_east"
  lon@long_name="Longitude"
  printVarSummary(lon)
EOF
end

def write_coordinate_description
  xdesc=create_xcoordinate
  ydesc=create_ycoordinate
  zdesc=create_zcoordinate
  tdesc=create_tcoordinate
  @outfil.puts "; NCL file created by #{$0}"
  @outfil.puts xdesc
  @outfil.puts ydesc
  @outfil.puts zdesc
  @outfil.puts tdesc
  @outfil.puts ""
end

def write_open_file_instructions
  @outfil.puts "; Open the binary data file"
  endianness=@options.match(/\w+_endian/).to_s
  unless endianness==nil || endianness==""
    endianness=endianness.split("_").map { |s| s.capitalize}.join
    @outfil.puts "  setfileoption(\"bin\",\"ReadByteOrder\",\"#{endianness}\")"
  else
    @outfil.puts ";  Please fill this up yourselves"
    @outfil.puts ";  setfileoption(\"bin\",\"ReadByteOrder\",\"endianness\")"
  end
  @write_out_code = "; Write out as a NetCDF file \n"
  @write_out_code += ";fout=addfile(\"#{@nclFile.chop}\",\"c\") \n"


  if @fileName.match(/^\^/) 
    filPath   = File.dirname(@ctlFile)
  else
    filPath   = ""
  end
  unless @fileName.match(/^\//)
    filPath   = File.dirname(@ctlFile)
  end 
  @fileName.gsub!("^","")
  @outfil.puts "  path=\"#{filPath}/#{@fileName}\""
  #@outfil.puts "  nlat=#{@nlat}"
  #@outfil.puts "  nlon=#{@nlon}"
  #@outfil.puts "  nlev=#{@nlev}"
  #@outfil.puts "  ntim=#{@ntim}"
  @outfil.puts "  rec_dims=(/nlat,nlon/)"
  @outfil.puts '  rec_type="float"' # add functionality for other types
  @fileReader="fbindirread"
  @fileReader="fbinrecread" if @options.match("sequential")
  @outfil.puts ""
end

def check_validity_of_var_names(vars,vnames)
  valid=true
  unless vars==:all
    vtemp=vars & vnames  # intersection of two arrays
    valid=false unless vtemp == vars
  end
  return(valid)
end

def calendar2indx
  puts "not yet implemented"
  terminateProgram
end
def parse_supplied_time(times)
  if times[0,1]==":"
    puts " ------%< ----------"
    puts "This format of time is not acceptable"
    terminateProgram
  end
  tarray=times.split(":")
  if tarray.size==1
    times=times+":"+times 
    tarray=times.split(":")
  end
  digit_len=tarray[0].match(/\d+/).length
  strng_len=tarray[0].length

  if digit_len==strng_len
    tarray[0]=(tarray[0].to_i-1).to_s
    tarray[1]=(tarray[1].to_i-1).to_s
    times=tarray.join(",")
    return times
  else
    calendar2indx
  end
  
end

def write_read_data_instructions(vars,times)
  if times==:tall
    itimes="0,ntim-1"
    istart=0
  else
    itimes=parse_supplied_time(times)
    istart=itimes.split(",")[0]
  end
  vnames=[]
  vnens=[]
  vdesc=[]
  vunits=[]
  @var_table.split("\n").each do |desc|
    vnames << desc.split(":")[0]
    darr   =  desc.split
    narr   =  darr.size
    tmp_ns =  darr[1].to_i
    tmp_ns = 1 if tmp_ns == 0 # in grads one can use 0 or 1 to mean 1 !
    vnens  << tmp_ns
    vdesc  << darr[3..narr-2].join(" ")
    vunits << darr[narr-1].gsub("[","").gsub("]","")
  end
  tot_num_ens_per_time_step=0
  vnens2=vnens.dup
  acc_nens_per_variable=vnens

  i=0
  for ens in vnens 
    tot_num_ens_per_time_step+=ens
    acc_nens_per_variable[i]+= vnens[i-1] if i>0
    i+=1
  end
  fens=vnens[0]

  if vars==:all
    vnames2=vnames
  else
    vnames2=vars
  end

  # check if the variables in vars are valid variables contained in the
  # ctl file
  valid=check_validity_of_var_names(vars,vnames)
  unless valid
    puts "One or more variable names you entered is invalid"
    puts "Check the grads ctl file and enter  valid variable names"
    terminateProgram
  end

  for vname in vnames2
    var_array="#{vname}(itt,il,:,:)"
    ivar= vnames.index(vname)
    read_command="#{@fileReader}(path,rec_num,rec_dims,rec_type )"
    nens=vnens2[ivar]
    @outfil.puts "      "
    @outfil.puts "  tim2=time(#{itimes.gsub(",",":")})"
    @outfil.puts "  ntim2=dimsizes(tim2)"
    @outfil.puts "  nens=#{nens}      "
    @outfil.puts "  #{vname}=new( (/ntim2,nens,nlat,nlon/), rec_type )"
    @outfil.puts "  do it=#{itimes}"
    @outfil.puts "    itt=it-#{istart}"
    @outfil.puts "    rec_num=it*#{tot_num_ens_per_time_step}"
    next_rec     =    acc_nens_per_variable[ivar] - vnens2[ivar]
    @outfil.puts "    rec_num=rec_num+#{next_rec}"
    @outfil.puts "    do il=0,nens-1"
    @outfil.puts "      #{var_array}=#{read_command}"
    @outfil.puts "      rec_num=rec_num+1"
    @outfil.puts "    end do"
    @outfil.puts "  end do"
    @outfil.puts "      "
    @outfil.puts "  #{vname}@units=\"#{vunits[ivar]}\"      "
    @outfil.puts "  #{vname}@long_name=\"#{vdesc[ivar]}\"      "
    @outfil.puts "  #{vname}!0=\"time\""
    @outfil.puts "  #{vname}!1=\"lev\""
    @outfil.puts "  #{vname}!2=\"lat\""
    @outfil.puts "  #{vname}!3=\"lon\""
    @outfil.puts "  #{vname}&lon=lon"
    @outfil.puts "  #{vname}&lat=lat"
    @outfil.puts "  #{vname}&lev=lev(:nens-1)"
    @outfil.puts "  #{vname}&time=tim2"
    @outfil.puts "  #{vname}@_FillValue=#{@fillValue}"
    @outfil.puts "  #{vname}@missing_value=#{@fillValue}"
    @outfil.puts "      "

    if nens>1
      @write_out_code+=";fout->#{vname}=#{vname} \n"
    else
      @write_out_code+=";fout-\>#{vname}=#{vname}(:,0,:,:) \n"
    end
    if @debug
      @outfil.puts "  #{vname}@map=True"
      @outfil.puts "  #{vname}@raster=True"
      @outfil.puts "  do it=#{itimes}"
      @outfil.puts "    itt=it-#{istart}"
      @outfil.puts "    ctime=ut_calendar(time(it),-2)      "
      @outfil.puts "    do il=0,nens-1"
      @outfil.puts "      clevel=lev(il)      "
      @outfil.puts "      #{vname}@title=\"Time=\"+ctime+\", Level=\"+clevel"
      @outfil.puts "      DebugPlot(#{var_array})"
      @outfil.puts "    end do"
      @outfil.puts "  end do"
    end
  end

@outfil.puts @write_out_code
end

def ctl_to_ncl(opts)
  check_existence_of_files(opts)
  @debug=true if opts[:plot]
  parse_ctl_file
  open_output_file
  write_coordinate_description
  write_open_file_instructions
  write_read_data_instructions opts[:vars],
                               opts[:times]
end
