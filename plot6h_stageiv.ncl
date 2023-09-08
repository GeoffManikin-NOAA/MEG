load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
begin

  ;start of period you want
  scriptyyyymmddhh="2022092812"

  ;how long you want accumulation window to be in hours
  acch=24

23.4;-89.;33.;-77
  ;bounds for plot
  minlat=23.4
  maxlat=33.0
  minlon=-77.0
  maxlon=-89.0
  
  scriptyear=toint(str_get_cols(scriptyyyymmddhh,0,3))
  scriptmonth=toint(str_get_cols(scriptyyyymmddhh,4,5))
  scriptday=toint(str_get_cols(scriptyyyymmddhh,6,7))
  scripthour=toint(str_get_cols(scriptyyyymmddhh,8,9))
  timeunits="hours since 1800-01-01 00:00"
  datemodel=ut_inv_calendar(scriptyear,scriptmonth,scriptday,scripthour,0,0,timeunits,0)
  datestart=ut_inv_calendar(scriptyear,scriptmonth,scriptday,scripthour,0,0,timeunits,0)
  
  enddate1=datestart+acch
  enddate1@units=timeunits
  endints=ut_calendar(enddate1,0)
  dateend=ut_inv_calendar(toint(endints(:,0)),toint(endints(:,1)),toint(endints(:,2)),toint(endints(:,3)),0,0,timeunits,0)
  datemodel@units=timeunits
  fdates=ispan(toint(datestart),toint(dateend),6)
  fhours=ispan(toint(datestart)-toint(datemodel),toint(dateend)-toint(datemodel),6)

  do h=0,dimsizes(fdates)-1
  thisdate=fdates(h)
  thisdate@units=timeunits
  modelstrings=tostring(ut_calendar(thisdate,-3))
  ms=tostring(ut_calendar(datemodel,-3))
  yearm=str_get_cols(ms,0,3)
  monthm=str_get_cols(ms,4,5)
  daym=str_get_cols(ms,6,7)
  hourm=str_get_cols(ms,8,9)
  mdhm=str_get_cols(ms,4,9)
  ymdm=str_get_cols(ms,0,7)
  year=str_get_cols(modelstrings,0,3)
  month=str_get_cols(modelstrings,4,5)
  day=str_get_cols(modelstrings,6,7)
  hour=str_get_cols(modelstrings,8,9)
  mdh=str_get_cols(modelstrings,4,9)
  ymd=str_get_cols(modelstrings,0,7)
  monthind=toint(month)
  months=(/"","January","February","March","April","May","June","July","August","September","October","November","December"/)

  ;********************************************************
  ;change path to wherever you have the unzipped ST4 files
  ;from /com2/pcpanl/prod/pcpanl.YYYYMMDD/*06h.gz
  ;********************************************************
  a = addfile("/lfs/h2/emc/stmp/geoffrey.manikin/precip/ST4."+modelstrings+".06h","r")

  if (fhours(h).eq.0) then
    precip=a->A_PCP_GDS5_SFC_acc6h
    precip1d=ndtooned(precip)
    indp=ind(ismissing(precip1d))
    precip1d(indp)=0.0
    precip=onedtond(precip1d,dimsizes(precip))
    precip=precip*.03937*0.0
    delete(precip1d)
    delete(indp)
  else
    variable="A_PCP_GDS5_SFC_acc6h"
    precipnew=a->$variable$
    precip1d=ndtooned(precipnew)
    indp=ind(ismissing(precip1d))
    precip1d(indp)=0.0
    precipnew=onedtond(precip1d,dimsizes(precipnew))
    delete(precip1d)
    delete(indp)
    precip=precip+(precipnew*.03937)
  end if

  lat=a->g5_lat_0
  lon=a->g5_lon_1
  precip@lon2d=lon
  precip@lat2d=lat
      

  wks  = gsn_open_wks("ps",ms+"precipverf"+tostring(h+1))
  
  res  = True

  res@mpMinLatF                = minlat
  res@mpMaxLatF                =  maxlat
  res@mpMinLonF                = minlon
  res@mpMaxLonF                = maxlon
  res@mpOutlineBoundarySets="AllBoundaries"
  res@mpDataBaseVersion="MediumRes"
  res@gsnMaximize=True
  res@tmXBLabelFontHeightF=.008
  res@tmYLLabelFontHeightF=.008
  res@gsnRightString=""
  res@gsnAddCyclic=False
  res@gsnLeftString="Stage IV valid "+hour+"Z "+day+ " "+months(monthind)+ " " +year+ " ("+sprinti("%0.1i",fhours(h))+"-hour accumulation)"
  res@mpOutlineDrawOrder="PostDraw"
  res@mpFillColor="grey75"
  res@cnFillColors=(/"transparent","lawngreen","green3","green4","blue1","dodgerblue1","cyan1","mediumpurple3","darkorchid3","darkorchid4","red2","red3","orangered2","darkorange2","lightsalmon1","yellow1","black"/)
  res@cnInfoLabelOn=False
  res@mpFillDrawOrder="PreDraw"
  res@cnLabelMasking=True
  res@mpGeophysicalLineColor="black"
  res@mpGeophysicalLineThicknessF=4.0
  res@mpNationalLineThicknessF=4.0
  res@mpUSStateLineThicknessF=3.0
  res@mpCountyLineThicknessF=.5
  res@mpNationalLineColor="black"
  res@mpUSStateLineColor="black"
  res@cnLineLabelsOn=False
  res@pmLabelBarHeightF=.05
  res@lbLabelFontHeightF=.008
  res@gsnLeftStringFontHeightF=.012
  res@cnFillOn=True
  res@mpFillOn=True
  res@cnFillMode="AreaFill"
  res@cnLevelSelectionMode="ExplicitLevels"
  res@cnLevels=(/.01,.25,.5,.75,1.0,1.5,2.0,2.5,3.0,4.0,5.0,7.5,10.0,12.5,15.0,20.0/)
;  res@cnLevels=(/.01,0.1,.25,.5,.75,1.0,1.5,2.0,2.5,3.0,3.5/)
;   res@cnLevels=(/.01,0.1,.25,.5,.75,1.0,1.5,2.0,2.5,3.0,4.0,5.0,6.0,8.0,10.0/)
;  res@cnLevels=(/.1,.5,1.0,2.0,4.0,6.0,8.0,10.0,15.0,20.0,25.0,30.0,35.0,40.0,50.0,60.0/)
;  res@lbLabelStrings=(/"0.1","0.5","1.0","2.0","4.0","6.0","8.0","10.0","15.0","20.0","25.0","30.0","35.0","40.0","50.0","60.0"/)
   res@lbLabelStrings=(/"0.01","0.25","0.5","0.75","1.0","1.5","2.0","2.5","3.0","4.0","5.0","7.5","10.0","12.5","15.0","20.0"/)
;  res@lbLabelStrings=(/"0.1","0.10","0.25","0.5","0.75","1.0","1.5","2.0","2.5","3.0","3.5"/)
;  res@lbLabelStrings=(/"0.1","0.10","0.25","0.5","0.75","1.0","1.5","2.0","2.5","3.0","4.0","5.0","6.0","8.0","10.0"/)
  res@lbLabelStride=1
  res@cnLinesOn=False
  res@lbLabelAutoStride=False
  res@mpLimitMode="LatLon"
  res@gsnDraw=False
  res@mpProjection="Mercator"
  res@gsnFrame=False


  res@cnLineLabelInterval=1
  res@cnLineLabelDensityF=1.5
  plot = gsn_csm_contour_map(wks,precip,res) 

  
draw(plot)
frame(wks)
delete(wks)

;***********************************************
;may need to remove the "-rotate 270" depending on domain aspect ratio
;I could probably automate that decision but haven't tried
;***********************************************

system("convert -rotate 270 -density 300 -trim +repage "+ms+"precipverf"+tostring(h+1)+".ps -density 300 -resize 700 -trim +repage "+ms+"precipverf"+tostring(h+1)+".gif")
;system("convert -density 300 -trim +repage "+ms+"precipverf"+tostring(h+1)+".ps -density 300 -resize 700 -trim +repage "+ms+"precipverf"+tostring(h+1)+".gif")

print("finished "+tostring(h+1)+" of "+tostring(dimsizes(fhours)))
end do

system("scp "+ms+"precipverf*.gif wd20mg@emcrzdm:/home/people/emc/www/htdocs/mmb/gmanikin/meg/short/images_short/hold8/")
end
