require 'fileutils'
src="./CMS_Retrieve3.ncl"
dest="./SysE_DB_get.ncl"
FileUtils.ln_sf(src, dest, :verbose=>true)
