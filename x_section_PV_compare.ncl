; Plot PV cross section through Joaquin
; ===========================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
;load "~/ncl/lib/gempak.ncl"
;load "~/ncl/lib/tTick.ncl"
;load "~/ncl/lib/ut_string.ncl"
;load "~/ncl/lib/shea_util.ncl"

; ===========================================

begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")

dir_out = "./"

;*******************************************************
center_lat = 25.0
center_lon = 360.0-72.0
minlat = center_lat-7.0
maxlat = center_lat+7.0

syyyy = 2015
smm = 9
sdd = 30
shh = 12

  timeUnits = "hours since 1800-01-01 00:00:00"

  sdate = cd_inv_calendar(syyyy,smm,sdd,shh,00,00,timeUnits,0)
  print("Date:  "+ut_string(sdate,""))

   year = cd_string(sdate,"%Y")
   mon = cd_string(sdate,"%N")
   day = cd_string(sdate,"%D")
   hr = cd_string(sdate,"%H")

print("yyyymmddhh:  "+year+mon+day+hr)

name = "xsection_joaquin_"+year+mon+day+hr

; ******************************************************
; Load files
; ******************************************************
    gfs_file = addfile("gfs.20150930.t12z.pgrb2.0p25.f000.grib2","r")
    fv3_file = addfile("fv3gfs.20150930.t12z.pgrb2.0p25.f000.grib2","r")

; ******************************************************

print("Calculating theta-e and theta...")
;Compute the equivalent temperature in the 1000-100 hPa layer.
           t := gfs_file->TMP_P0_L100_GLL0({10000:100000},::-1,:)
           rh := gfs_file->RH_P0_L100_GLL0({10000:100000},::-1,:)
           pres := gfs_file->lv_ISBL0({10000:100000})
           phpa := pres
           phpa := pres/100
           q := t
           q := mixhum_ptrh(conform(t,phpa,0),t,rh,1)
           thetae_gfs := t
           thetae_gfs =t+(2.6e6/1004)*q
           ;printVarSummary(thetae_gfs)
           ;printMinMax(thetae_gfs,True)

           theta_gfs = pot_temp(pres, t, 0, False)

           ;printVarSummary(theta_gfs)
           ;printMinMax(theta_gfs,True)

;Compute the equivalent temperature in the 1000-100 hPa layer.
           t := fv3_file->TMP_P0_L100_GLL0({10000:100000},::-1,:)
           rh := fv3_file->RH_P0_L100_GLL0({10000:100000},::-1,:)
           pres := fv3_file->lv_ISBL0({10000:100000})
           phpa := pres
           phpa := pres/100
           q := t
           q := mixhum_ptrh(conform(t,phpa,0),t,rh,1)
           thetae_fv3 := t
           thetae_fv3 =t+(2.6e6/1004)*q
           ;printVarSummary(thetae_fv3)
           ;printMinMax(thetae_fv3,True)

           theta_fv3 = pot_temp(pres, t, 0, False)
           
           ;printVarSummary(theta_fv3)
           ;printMinMax(theta_fv3,True)

;------------------------------------------

calc = False

if calc .eq. True then

  lev_pv := thetae_gfs&lv_ISBL0
  upv := gfs_file->UGRD_P0_L100_GLL0({lev_pv},::-1,:)
  vpv := gfs_file->VGRD_P0_L100_GLL0({lev_pv},::-1,:)
  tpv := gfs_file->TMP_P0_L100_GLL0({lev_pv},::-1,:)
  ;  lev_pv@units = "Pa"

  print("Calculating isobaric PV...")
  pv_gfs = pot_vort_isobaric(lev_pv,upv,vpv,tpv,tpv&lat_0,1,0)
  pv_gfs = pv_gfs*(10^6)
  copy_VarCoords(upv,pv_gfs)
;  printVarSummary(pv_gfs)

  system("/bin/rm -f gfs_pv_"+year+mon+day+hr+".nc")   ; remove any pre-existing file
  ncdf = addfile("gfs_pv_"+year+mon+day+hr+".nc","c")  ; open output netCDF file
  ncdf->pv_gfs = pv_gfs

else if calc .eq. False then
  
  gfs_pv_file = addfile("gfs_pv_"+year+mon+day+hr+".nc","r")
  pv_gfs = gfs_pv_file->pv_gfs(:,:,:)
;  printVarSummary(pv_gfs)

end if
end if




calc = False

if calc .eq. True then

  lev_pv := thetae_fv3&lv_ISBL0
  upv := fv3_file->UGRD_P0_L100_GLL0({lev_pv},::-1,:)
  vpv := fv3_file->VGRD_P0_L100_GLL0({lev_pv},::-1,:)
  tpv := fv3_file->TMP_P0_L100_GLL0({lev_pv},::-1,:)
  ;  lev_pv@units = "Pa"

  print("Calculating isobaric PV...")
  pv_fv3 = pot_vort_isobaric(lev_pv,upv,vpv,tpv,tpv&lat_0,1,0)
  pv_fv3 = pv_fv3*(10^6)
  copy_VarCoords(upv,pv_fv3)
  printVarSummary(pv_fv3)

  system("/bin/rm -f fv3_pv_"+year+mon+day+hr+".nc")   ; remove any pre-existing file
  ncdf = addfile("fv3_pv_"+year+mon+day+hr+".nc","c")  ; open output netCDF file
  ncdf->pv_fv3 = pv_fv3

else if calc .eq. False then

  fv3_pv_file = addfile("fv3_pv_"+year+mon+day+hr+".nc","r")
  pv_fv3 = fv3_pv_file->pv_fv3(:,:,:)
;  printVarSummary(pv_fv3)

end if
end if



;  do d=0,3
;    pv=smth9(pv,.5,.25,True)
;  end do

;==============================================
; Create Shaded Map
;==============================================

    wks_type = "png"

    wks_type@wkWidth = 1600
    wks_type@wkHeight = 1600

    wks = gsn_open_wks(wks_type,name)

    gsn_define_colormap(wks,"MPL_RdBu")

    panel = new ( 2 , graphic)
;**********************************************

do i = 0,1      ; loop through making panels 0-1


    pwres = True

    pwres@gsnDraw   = False
    pwres@gsnFrame  = False

    pwres@tmXTOn = False
    pwres@trYReverse = True
    pwres@tiMainJust = "CenterCenter"
    pwres@tiMainPosition = "Center" 
    pwres@tiMainOffsetYF = .02
    pwres@gsnAddCyclic = False 
    pwres@trXReverse = True

	pwres@gsnPaperOrientation  = "landscape"              ; when maximizing, keep the orientation as portrait
    pwres@cnLevelSelectionMode = "ExplicitLevels"                ; manually select the levels
    pwres@cnLevels = (/0.5,1.0,1.5,2.0,4.0,6.0,8.0,10.0/)
    pwres@cnFillColors = (/-1,80,89,99,56,44,37,30,23/)
    pwres@cnFillOn = True                                      ; turn on contour shading     
    pwres@cnLinesOn = False                         ; don't draw the contour lines
    pwres@cnInfoLabelOn = False             ; don't draw the info label
    pwres@cnLineLabelsOn = False                    ; don't draw the contour line labels
    pwres@cnFillDrawOrder = "PreDraw"
    pwres@lbAutoManage = False  
    pwres@pmLabelBarHeightF = 0.08
    pwres@pmLabelBarWidthF = 0.6
    pwres@lbLabelAutoStride = True
    pwres@lbLabelFontHeightF = 0.015
    pwres@lbBoxLinesOn  = True

    pwres@tiYAxisString = ""
    pwres@tiMainString = ""    ; Specify Title
    pwres@gsnLeftStringOrthogonalPosF = .0075
    pwres@gsnLeftStringFontHeightF = .013

if i .eq. 0 then
    pwres@gsnLeftString = "GFS"
else if i .eq. 1 then
    pwres@gsnLeftString = "FV3GFS"
end if
end if
    pwres@gsnRightStringOrthogonalPosF = .0075
    pwres@gsnRightStringFontHeightF = .013
    pwres@gsnRightString = "Valid: "+ut_string(sdate,"")+" (F000)"
    pwres@gsnRightStringOrthogonalPosF = .008
    pwres@cnSmoothingOn = True
    pwres@cnSmoothingDistanceF = 0.0001
    pwres@tmYRMode = "Automatic"          ; turn off special labels on right axis
    pwres@tmYROn = False
    
    pwres@tmYLMode = "Explicit"
    pwres@tmYLValues = (/150,200,300,400,500,600,700,800,900,1000/)  ; Create tick marks
    pwres@tmYLLabels = (/"150","200","300","400","500","600","700","800","900","1000"/)  ; Create labels

;**********************************************

    tres = True

    tres@gsnDraw   = False
    tres@gsnFrame  = False

    tres@cnInfoLabelOn = False
    tres@cnLineLabelsOn = False
    tres@tmXTOn = False
    tres@trYReverse = True
    tres@trXReverse = True

    tres@gsnLeftString = ""
    tres@gsnRightString = ""

    tres@cnLevelSelectionMode = "ManualLevels" 
    tres@cnMinLevelValF = 250
    tres@cnMaxLevelValF = 500
    tres@cnLevelSpacingF = 3.0
    tres@cnLineThicknessF = 6.0
    tres@cnLineColor = "black"
    tres@cnLineLabelFontColor = "black"
    tres@cnLineLabelsOn = True
    tres@cnLabelMasking = True
    tres@cnLineLabelBackgroundColor = -1
    tres@cnLineLabelInterval = 2
    tres@cnLineLabelPlacementMode = "Computed"
    tres@cnLineLabelDensityF = 0.8
    tres@cnLineLabelAngleF = 0.0
    tres@cnLineLabelFontHeightF = 0.016
    tres@cnSmoothingOn = True
    tres@cnSmoothingDistanceF = 0.0001
    tres@tmYRMode = "Automatic"          ; turn off special labels on right axis
    tres@tmYROn = False

;**********************************************

    teres = True

    teres@gsnDraw   = False
    teres@gsnFrame  = False

    teres@cnInfoLabelOn = False
    teres@cnLineLabelsOn = False
    teres@tmXTOn = False
    teres@trYReverse = True
    teres@trXReverse = True

    teres@gsnLeftString = ""
    teres@gsnRightString = ""

    teres@cnLevelSelectionMode = "ManualLevels" 
    teres@cnMinLevelValF = 0
    teres@cnMaxLevelValF = 500
    teres@cnLevelSpacingF = 3.0
    teres@cnLineThicknessF = 3.0
    teres@cnLineColor = "darkgreen"
    teres@cnLineLabelFontColor = "darkgreen"
    teres@cnLineLabelsOn = True
    teres@cnLabelMasking = True
    teres@cnLineLabelBackgroundColor = -1
    teres@cnLineLabelInterval = 3
    teres@cnLineLabelPlacementMode = "Computed"
    teres@cnLineLabelDensityF = 0.8
    teres@cnLineLabelAngleF = 0.0
    teres@cnLineLabelFontHeightF = 0.009
    teres@cnSmoothingOn = True
    teres@cnSmoothingDistanceF = 0.01
    teres@tmYRMode = "Automatic"          ; turn off special labels on right axis
    teres@tmYROn = False

;**********************************************

if i .eq. 0 then
    plot0 = gsn_csm_pres_hgt(wks,pv_gfs({100000:15000},{maxlat:minlat},{center_lon}),pwres)
    theta0 = gsn_csm_pres_hgt(wks,theta_gfs({100000:15000},{maxlat:minlat},{center_lon}),tres)
    thetae0 = gsn_csm_pres_hgt(wks,thetae_gfs({100000:15000},{maxlat:minlat},{center_lon}),teres)

    overlay(plot0,theta0)
    ;overlay(plot0,thetae0)
    panel(i) = plot0
    delete(plot0)
end if

if i .eq. 1 then
    plot1 = gsn_csm_pres_hgt(wks,pv_fv3({100000:15000},{maxlat:minlat},{center_lon}),pwres)
    theta1 = gsn_csm_pres_hgt(wks,theta_fv3({100000:15000},{maxlat:minlat},{center_lon}),tres)
    thetae1 = gsn_csm_pres_hgt(wks,thetae_fv3({100000:15000},{maxlat:minlat},{center_lon}),teres)

    overlay(plot1,theta1)
    ;overlay(plot1,thetae1)
    panel(i) = plot1
    delete(plot1)
end if

end do ; end i = panel number

;==============================================
; create panel
;=============================================
 plres                 = True
; plres@gsnPanelRowSpec = True                   ; tell panel what order to plot
; plres@gsnPanelYWhiteSpacePercent = 0
 plres@gsnPanelXWhiteSpacePercent = 0
 gsn_panel(wks,panel,(/1,2/),plres)

;**********************************************

system("convert -trim "+name+".png "+name+".png")

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end
