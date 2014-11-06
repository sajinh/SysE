class Lev
  def main (zdef)
    @zinfo = zdef.split
    nz     = @zinfo[0].to_i
    ztyp   = @zinfo[1].downcase
    @z1    = @zinfo[2].to_f
    zint   = @zinfo[3].to_f
    @z2    = @z1 + (nz-1)*zint
    @nlev  = nz
    send(ztyp)
  end

  def linear 
    return "lev=#{@z1}" if @nlev == 1
    "lev=fspan(#{@z1},#{@z2},#{@nlev})"
  end

  def levels
    zinfo=@zinfo.reverse
    zinfo.pop
    zinfo.pop
    "lev=(/#{zinfo.reverse.join(",")}/)"
  end
end
require 'pp'
class Lat
  def main (ydef)
    @yinfo = ydef.split
    ny     = @yinfo[0].to_i
    ytyp   = @yinfo[1].downcase
    @y1    = @yinfo[2].to_f
    yint   = @yinfo[3].to_f
    @y2    = @y1 + (ny-1)*yint
    @nlat  = ny
    send(ytyp)
  end

  def linear 
    return "lat=#{@y1}" if @nlat == 1
    "lat=fspan(#{@y1},#{@y2},#{@nlat})"
  end

  def levels
    yinfo=@yinfo.reverse
    yinfo.pop
    yinfo.pop
    "lat=(/#{yinfo.reverse.join(",")}/)"
  end
end
class Lon
  def main (xdef)
    @xinfo = xdef.split
    nx     = @xinfo[0].to_i
    xtyp   = @xinfo[1].downcase
    @x1    = @xinfo[2].to_f
    xint   = @xinfo[3].to_f
    @x2    = @x1 + (nx-1)*xint
    @nlon  = nx
    send(xtyp)
  end

  def linear 
    return "lat=#{@x1}" if @nlon == 1
    "lon=fspan(#{@x1},#{@x2},#{@nlon})"
  end

  def levels
    xinfo=@xinfo.reverse
    xinfo.pop
    xinfo.pop
    "lon=(/#{xinfo.reverse.join(",")}/)"
  end
end
