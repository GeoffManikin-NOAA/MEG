#!/bin/ksh
# Script to read mesonet data in NCEP BUFR and output
# equivalent text and gempak files.
#
# Usage: sh runpbmnet2gem.sh <pb file w/ full path > <inclrestr or norestr>
#							|-> include restricted data or
# 				    			    do not include restricted data
#
# 2006-05-02 S. Bender
# ----------------------------------------------------------------------------------------

if [ $# -lt 2 ]; then
  echo 'usage: sh runpbmnet2gem.sh <pb file with full path> <inclrestr or norestr>'
  echo 'try again'
  exit
fi

pbfile=$1
restrstatus=$2
cyc=$3
PBMNET2GEMEXEC=/meso/save/Geoffrey.Manikin/mesonet/pbmnet2gem.x

# Make working directory, cd to it.
# ---------------------------------
WDIR=/stmp/Geoffrey.Manikin/pbmnet2gem/newr
if [ ! -d $WDIR ]; then
  mkdir -p $WDIR
else
  rm $WDIR/*
fi
 
cd $WDIR
ln -sf $pbfile fort.11

# write out parm file for input to pbmnet2gem
# -------------------------------------------
PARMFILE=pbmnet2gem.parm
echo > $PARMFILE
echo ' &mnet2gemtxtparm' >> $PARMFILE
if [ $restrstatus = inclrestr ]; then
  echo '  l_inclrestr = .true.' >> $PARMFILE
else
  echo '  l_inclrestr = .false.' >> $PARMFILE
fi
echo '/' >> $PARMFILE
echo >> $PARMFILE
echo '  Cards for pbmnet2gem -- ' $(date) >> $PARMFILE

# Run pbmnet2gem in order to create station table(s) and text files
# of data
# -----------------------------------------------------------------
$PBMNET2GEMEXEC < $PARMFILE

# Make sure table files contain only unique stations.
# ---------------------------------------------------
echo
tables=$(ls msonet.tbl.*)
for tab in $tables
do
##  echo processing $tab
  sort $tab > $tab.sorted
  prev_sid='XXXXXXX'
  > $table.new
  while read line
  do
    sid=$(echo $line | cut -d" " -f1)
    if [ $sid != $prev_sid ]; then
##    if [ $sid = $prev_sid ]; then
##      echo "duplicated sid: " $sid
##    else
      echo "$line" >> $tab.new
    fi

    prev_sid=$sid
  done < $tab.sorted # while read line

  rm $tab.sorted
  mv $tab.new $tab
done # for tab in $tables

# For each table and text file, create a gempak file with the station table, 
# then add the corresponding data to it.  The gempak setting for TIMSTN
# may need to be altered if a time window wider than 3 hrs is used.
# --------------------------------------------------------------------------
typeset -Z4 index

. /nwprod/gempak/.gempak
cp /meso/save/Geoffrey.Manikin/mesonet/coltbl.xwp $WDIR

hmtf=$(ls msonet.txt.* | wc -l) # hmtf = how many text files
echo '**** --> There are '$hmtf' GEMPAK files to create.'
echo 

hhmms=$(ls msonet.txt.* | cut -c 12-15)

##echo $hhmms
for index in $hhmms
do
  echo 'Creating GEMPAK file for' $index

sfcfil << EOFsfcfil >> sfcfil.out
sfoutf=msonet.gem.$index
sfprmf=pres;tmpc;dwpc;uwnd;vwnd;tvrc;tvfl;gust
stnfil=msonet.tbl.$index
shipfl=no
timstn=180/0
sffsrc=text
r

e
EOFsfcfil

# Add data in text files to newly created gempak files (which at this point only
# contain table info).
# ------------------------------------------------------------------------------

sfedit << EOFsfedit >> sfedit.out
sfefil=msonet.txt.$index
sffile=msonet.gem.$index
r

e
EOFsfedit

  echo 'Done creating GEMPAK file for ' $index
done # for index in $hmtf

# Run sfmap to get a generic plot to see if it works.
# ---------------------------------------------------
echo 
echo "Creating dist.gif..."
echo

for index in $hhmms
do

echo "processing "$index

sfmap << EOFsfmap >> sfmap.out
 AREA    = dset
 GAREA   = 10;-170;75;-10
 SATFIL  =
 RADFIL  =
 IMCBAR  =
 SFPARM  = mark:15:2:1
 DATTIM  = all
 SFFILE  = msonet.gem.$index
 COLORS  = 2
 MAP     = 30
 MSCALE  = 0
 LATLON  = 30/10/2
 TITLE   =
 CLEAR   = no
 PANEL   = 0
 DEVICE  = gif | dist.gif | 800;600
 PROJ    = mer
 FILTER  = no
 TEXT    = 1
 LUTFIL  =
 STNPLT  =
 CLRBAR  =

r

EOFsfmap

done

sfmap << EOFsfmap1 >> sfmap.out
e

EOFsfmap1

gpend

echo "Done creating dist.gif..."
echo

# Change group and permissions on file if restricted data are included.
# ---------------------------------------------------------------------
if [ $restrstatus = inclrestr ]; then
  chgrp rstprod $WDIR/*
  chmod 640 $WDIR/*
fi

# Finished!
# ---------
echo 'Done!'

prevcyc=`expr $cyc - 1`
if [ $prevcyc -lt 10 ]; then
  prevcyc='0'$prevcyc
fi

if [ $cyc -eq 0 ]; then
  prevcyc=23
fi

mkdir /ptmp/Geoffrey.Manikin/mesonet2
mv msonet.gem.${prevcyc}54 /ptmp/Geoffrey.Manikin/mesonet2/msonet${cyc}.gem.001
mv msonet.gem.${prevcyc}55 /ptmp/Geoffrey.Manikin/mesonet2/msonet${cyc}.gem.002
mv msonet.gem.${prevcyc}57 /ptmp/Geoffrey.Manikin/mesonet2/msonet${cyc}.gem.003
mv msonet.gem.${prevcyc}58 /ptmp/Geoffrey.Manikin/mesonet2/msonet${cyc}.gem.004
mv msonet.gem.${cyc}00 /ptmp/Geoffrey.Manikin/mesonet2/msonet${cyc}.gem.005
mv msonet.gem.${cyc}01 /ptmp/Geoffrey.Manikin/mesonet2/msonet${cyc}.gem.006
mv msonet.gem.${cyc}03 /ptmp/Geoffrey.Manikin/mesonet2/msonet${cyc}.gem.007
mv msonet.gem.${cyc}07 /ptmp/Geoffrey.Manikin/mesonet2/msonet${cyc}.gem.008
return
