#!/bin/ksh
                                                                                      
set -x

mkdir /ptmp/wx20mg/temp3
cd /ptmp/wx20mg/temp3

ymdh=2013010421
ymd=`echo $ymdh | cut -c1-8`
YEAR=`echo $ymdh | cut -c1-4`
MONTH=`echo $ymdh | cut -c1-6`
DAY=`echo $ymdh | cut -c1-8`

hpsstar get /NCEPPROD/hpssprod/runhistory/2year/rh${YEAR}/$MONTH/$DAY/com_rtma_prod_rtma.${DAY}18-23.tar $(hpsstar inx /hpssprod/runhistory/2year/rh${YEAR}/$MONTH/$DAY/com_rtma_prod_rtma.${DAY}18-23.tar|grep 'prepbufr')

exit
