
procedure mymap(res:logical,opt:logical)
begin
	if (opt.and.isatt(opt,"latlon")) then
	res@gsnAddCyclic = False
	res@mpMinLatF      = opt@latlon(0)
	res@mpMaxLatF             = opt@latlon(1)
	res@mpMinLonF             = opt@latlon(2)
	res@mpMaxLonF             = opt@latlon(3)
        res@mpCenterLonF = (res@mpMinLonF+res@mpMaxLonF)/2. 
	end if
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::
; Resources to make line contours on top of shaded contours
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::

procedure myfillcontour(res:logical, opt:logical)


begin
res                 = True                ; make plot mods
        if (opt.and.isatt(opt,"clevs")) then
        res@cnLevelSelectionMode = "ExplicitLevels"
        res@cnLevels             = opt@clevs
        end if

res@lbLabelBarOn    = False
res@cnSmoothingOn   = True
res@cnFillOn              = True
res@cnLinesOn             = True
res@cnLineColor = "black"
res@cnLineLabelsOn        = False    ; turn off line labels
res@cnInfoLabelOn         = False
res@gsnContourNegLineDashPattern = 1 ;
res@gsnSpreadColors = True

end
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::
; Resources to make only line contours
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::

procedure mycontour(res:logical, opt:logical)


begin
res                 = True                ; make plot mods
        if (opt.and.isatt(opt,"clevs")) then
        res@cnLevelSelectionMode = "ExplicitLevels"
        res@cnLevels             = opt@clevs
        end if


res@lbLabelBarOn    = False
res@cnSmoothingOn   = True
res@cnFillOn              = False
res@cnLinesOn             = True
res@cnLineLabelsOn        = False    ; turn off line labels
res@cnInfoLabelOn         = False
res@cnLineColor = "black"
res@gsnContourNegLineDashPattern = 1 ;

end
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::
; Resources to make only shaded contours
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::

 procedure myfill(res:logical, opt:logical)


begin
  res                 = True                ; make plot mods
  if (opt.and.isatt(opt,"clevs")) then
    res@cnLevelSelectionMode = "ExplicitLevels"
    res@cnLevels             = opt@clevs
  end if

  res@lbLabelBarOn    = False
  if isatt(opt,"label_bar")
    if opt@label_bar
      res@lbLabelBarOn=True
      res@lbLabelAutoStride=True
    end if
  end if
  res@cnSmoothingOn   = True
  res@cnFillOn              = True
  res@cnLinesOn             = False
  res@cnLineLabelsOn        = False    ; turn off line labels
  ;res@cnLineColor = "black"
  res@cnInfoLabelOn         = False
  ;res@gsnContourNegLineDashPattern = 1 ;
  ;res@gsnSpreadColors = True
end
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::
; Resources to make vectors plus line contours on top of shaded contours
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::

procedure myvectorcontour(res:logical, opt:logical)

begin
res                 = True                ; make plot mods
        if (opt.and.isatt(opt,"clevs")) then
        res@cnLevelSelectionMode = "ExplicitLevels"
        res@cnLevels             = opt@clevs
        end if

res@lbLabelBarOn    = False
res@cnSmoothingOn   = True
res@cnFillOn              = True
res@cnLinesOn             = True
res@cnLineColor = "black"
res@cnLineLabelsOn        = False    ; turn off line labels
res@cnInfoLabelOn         = False
res@gsnScalarContour     = True
res@gsnContourNegLineDashPattern = 1 ;
res@gsnSpreadColors = True

res@mpMonoFillColor       = True
res@mpFillOn  = False
res@mpDefaultFillColor = "white"
res@mpDefaultFillPattern=-1
res@mpOutlineOn           = True
res@mpOutlineDrawOrder = "PostDraw"
end


procedure myvectorfill(res:logical, opt:logical)

begin
  res                 = True                ; make plot mods
        if (opt.and.isatt(opt,"clevs")) then
        res@cnLevelSelectionMode = "ExplicitLevels"
        res@cnLevels             = opt@clevs
        end if

  res@lbLabelBarOn    = False
  res@cnSmoothingOn   = True
  res@cnFillOn              = True
  res@cnLinesOn             = False
  res@cnLineColor = "black"
  res@cnLineLabelsOn        = False    ; turn off line labels
  res@cnInfoLabelOn         = False
  res@gsnScalarContour     = True
  res@gsnSpreadColors = True

  res@mpMonoFillColor       = True
  res@mpFillOn  = False
  res@mpDefaultFillColor = "white"
  res@mpDefaultFillPattern=-1
  res@mpOutlineOn           = True
  res@mpOutlineDrawOrder = "PostDraw"
end

procedure setvcskip(res,skip)
begin
  res@vcMinDistanceF = skip ; to thin out the arrows
end


procedure setvcscl(res,mag,len)
begin
  res@vcRefMagnitudeF           = mag
  res@vcRefLengthF              = len
end

procedure setvc(res,color,style,thick)
;# Styles are "FillArrow", "LineArrow", "WindBarb", "CurlyVector"
begin
  res@vcGlyphStyle            = style
  res@vcLineArrowColor        = color           ; change vector color
  res@vcLineArrowThicknessF   = thick               ; change vector thickness
  res@vcVectorDrawOrder       = "PostDraw"  
end

procedure setvcanno(res,color,up)
begin
  res@vcRefAnnoOrthogonalPosF   = up
  res@vcRefAnnoArrowLineColor   = color
  res@vcRefAnnoArrowUseVecColor = False           ; don't use vec color for ref
end

procedure novcanno(res)
begin
  res@vcRefAnnoOn=False
end

procedure setcn(res,clr,thick)
begin
res@cnLineColor=clr
res@cnLineThicknessF=thick
end

procedure setcstyle(res,style)
begin
res@xyDashPatterns    = style
end

procedure setstring(res,fhgt,left,right)
begin
res@gsnStringFontHeightF = fhgt
res@gsnLeftString=left
res@gsnRightString=right
end

function openwks(format:string,filename:string,colormap:string)
begin
wks  = gsn_open_wks(format,filename)              ; open a ps plot
gsn_define_colormap(wks,colormap)              ; choose colormap
return wks
end

function open_wks(format:string,filename:string,colormap:string)
begin
  return(openwks(format,filename,colormap))
end

procedure sety1y2(res,ymin,ymax)
begin
  res@trYMinF  = ymin
  res@trYMaxF  = ymax
end

procedure xt_minmax(res,xmin,xmax,units)
begin
hour=0
minute=0
second=0
yr1=xmin(0)
mo1=xmin(1)
dy1=xmin(2)
yr2=xmax(0)
mo2=xmax(1)
dy2=xmax(2)

x1=ut_inv_calendar(yr1,mo1,dy1,hour,minute,second,units,0)
x2=ut_inv_calendar(yr2,mo2,dy2,hour,minute,second,units,0)
res@trXMinF=x1
res@trXMaxF=x2
end

procedure yt_minmax(res,ymin,ymax,units)
begin
yr1=ymin(0)
mo1=ymin(1)
dy1=ymin(2)
yr2=ymax(0)
mo2=ymax(1)
dy2=ymax(2)

hour=0
minute=0
second=0
y1=ut_inv_calendar(yr1,mo1,dy1,hour,minute,second,units,0)
y2=ut_inv_calendar(yr2,mo2,dy2,hour,minute,second,units,0)
res@trYMinF=y1
res@trYMaxF=y2
end

procedure x_minmax(res,x1,x2)
begin
res@trXMinF=x1
res@trXMaxF=x2
end

procedure y_minmax(res,y1,y2)
begin
res@trYMinF=y1
res@trYMaxF=y2
end

procedure drawmarker(res,mark:string)
;mark can be "Markers" or "Lines" or "MarkLines"
begin
res@xyMarkLineModes=mark
end

procedure yrefline(res,refline,color1,color2)
begin
res@gsnYRefLine=refline
res@gsnAboveYRefLineColor=color1
res@gsnBelowYRefLineColor=color2
end

procedure noframe(res)
begin
  res@gsnFrame=False
end
procedure nodraw(res)
begin
  res@gsnDraw=False
end


function plot_it(wks,var,res)
begin
  opt = True
  nodraw(res)
  noframe(res)
  if isatt(var,"clevs")
    opt@clevs=var@clevs
  end if
    mycontour(res,opt)
  if isatt(var,"shaded")
    myfill(res,opt)
  end if
  if isatt(var,"raster")
    myfill(res,opt)
    res@cnFillMode = "RasterFill"
  end if
  if isatt(var,"title")
    res@tiMainString=var@title
  end if
  if isatt(var,"colormap")
     gsn_define_colormap(wks,var@colormap)
     res@gsnSpreadColors = False
  end if
  res@lbLabelBarOn=True
  res@lbLabelAutoStride=True
  if isatt(var,"nolabel")
    res@lbLabelBarOn=False
  end if
  if isatt(var,"map")
    lat = var&lat
    lon = var&lon
    if isatt(var,"latlon")
      opt@latlon=var@latlon
    else
      opt@latlon=(/min(lat),max(lat),min(lon),max(lon)/)
    end if
    mymap(res,opt)
    plot = gsn_csm_contour_map(wks,var,res)
  else
    plot = gsn_csm_contour(wks,var,res)
  end if
  return(plot)
end

procedure DebugPlot(var)
begin
  if isatt(var,"type")
    type=var@type
  else
    type="x11"
  end if
  if isatt(var,"fname")
    fname=var@fname
  else
    fname="test"
  end if
  wks = openwks(type, fname, "testcmap")
  res=True
  plot=plot_it(wks,var,res)
  draw(plot)
  frame(wks)
end

procedure colored_map(__var)
begin
  var=__var
  var@map=True
  var@shaded=True
  DebugPlot(var)
end
procedure shaded_map(var)
begin
  colored_map(var)
end
procedure shaded_plot(__var)
begin
  var=__var
  var@shaded=True
  DebugPlot(var)
end
function plot_contour(wks,__var,res)
begin
  var=__var
  return(plot_it(wks,var,res))
end
function plot_shaded(wks,__var,res)
begin
  var=__var
  var@shaded=True
  return(plot_it(wks,var,res))
end
function map_shaded(wks,__var,res)
begin
  var=__var
  var@shaded=True
  var@map=True
  return(plot_it(wks,var,res))
end


load "$SysE/lib/ncl/helpers/time_axis.ncl"
procedure DebugGraph(var)
begin
  wks  = gsn_open_wks("x11","a graph")
  res=True
   if isatt(var,"markers")
     res@xyMarkLineMode = "MarkLines"
     res@xyMarkers = var@markers
   end if
   if isatt(var,"labels")
     res@pmLegendDisplayMode = "Always"
     res@xyExplicitLegendLabels = var@labels
     res@pmLegendSide           = "Top"               ; Change location of 
  res@pmLegendParallelPosF   = .05                 ; move units right
  res@pmLegendOrthogonalPosF = 0.1                ; move units down
  res@pmLegendWidthF         = 0.15                ; Change width and
  res@pmLegendHeightF        = 0.18                ; height of legend.
  res@lgLabelFontHeightF     = .03                 ; change font height
  res@lgOrientation          = "horizontal"
  res@lgPerimOn              = False    
   end if
  if isatt(var,"time")
   pp("Plotting Time series")
    res@YearInc = var@YearInc
    res@MonthInc = var@MonthInc
    res@NoMinor = var@NoMinor
    plot = time_series_plot(wks,var&time,var,res)
  else
    plot = gsn_csm_y(wks,var,res)
  end if
end

function plot_vector(wks,uvar,vvar,res)
begin
  opt = True
  nodraw(res)
  noframe(res)
  if isatt(uvar,"title")
    res@tiMainString=var@title
  end if
  if isatt(uvar,"map")
    lat = uvar&lat
    lon = uvar&lon
    if isatt(uvar,"latlon")
      opt@latlon=uvar@latlon
    else
      opt@latlon=(/min(lat),max(lat),min(lon),max(lon)/)
    end if
    mymap(res,opt)
    plot = gsn_csm_vector_map(wks,uvar,vvar,res)
  else
    plot = gsn_csm_vector(wks,uvar,vvar,res)
  end if
  return(plot)
end

function plot_contour_n_vector(wks,cvar,uvar,vvar,res,vcres)
begin
  ; transfer attributes to cvar
  ;atts=getvaratts(cvar)
  ;do i = 0,dimsizes(atts)-1
  ;  vcres@$atts(i)$=uvar@$atts(i)$
  ;end do
  plot1 = plot_it(wks,cvar,res)
  nodraw(vcres)
  noframe(vcres)
  plot2 = plot_vector(wks,uvar,vvar,vcres)
  overlay(plot1,plot2)
  return(plot1)
end
