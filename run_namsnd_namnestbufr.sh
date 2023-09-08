#!/bin/sh
#BSUB -J dcs_tst
#BSUB -q "dev_shared"
#BSUB -R rusage[mem=2000]
#BSUB -cwd /ptmpp1/%U
#BSUB -o /ptmpp1/Geoffrey.Manikin/tst.j%J.out
#BSUB -W 01:00
#BSUB -P OBSPROC-T2O
#BSUB -R affinity[core]
#BSUB -n 1

set -eux

#########################################################################
#                                                                       #
# Script:  nam_bfr2gpk                                                  #
#                                                                       #
#  This script reads nam BUFR output and transfers it into GEMPAK       #
#  surface and sounding data files.                                     #
#                                                                       #
# Log:                                                                  #
# K. Brill/HPC          11/28/01                                        #
#########################################################################
## with hacked mods for specific test case -dcs

export STMP=/stmpp1/Geoffrey.Manikin
DATA=$STMP/nam.$$
mkdir -p $DATA

cd $DATA

domain=conus
DOMAIN=`echo $domain | tr '[a-z]' '[A-Z]'`
tmmark=tm00
cyc=00
COMIN=/ptmpp1/Geoffrey.Manikin/test
UTIL_EXECnam=/nwprod2/nam.v4.0.3/util/exec/wcoss.exec
UTIL_USHnam=/nwprod2/nam.v4.0.3/util/ush
PDY=20170518
module load gempak/ncep

#  Set input file name.

#Get the domain id number
export numdomain=`grep ${domain} $PARMnam/nam_nestdomains | awk '{print $2}'`

# CWORDX needed for cwordsh script, which calls the cwordsh exec
export CWORDX=${UTIL_EXECnam}/cwordsh


#${UTIL_USHnam}/cwordsh unblk $COMIN/nam.t${cyc}z.class1.bufr_${domain}nest.${tmmark} class1.bufr_${domain}nest.${tmmark}_unblk
#${UTIL_USHnam}/cwordsh block class1.bufr_${domain}nest.${tmmark}_unblk class1.bufr_${domain}nest.${tmmark}_blk
${UTIL_USHnam}/cwordsh block $COMIN/nam.t${cyc}z.class1.bufr_${domain}nest.${tmmark} class1.bufr_${domain}nest.${tmmark}_blk

INFILE=class1.bufr_${domain}nest.${tmmark}_blk
#cp $COMIN/nam.t${cyc}z.class1.bufr_${domain}nest.${tmmark} class1.bufr_${domain}nest.${tmmark}.orig
#INFILE=class1.bufr_${domain}nest.${tmmark}.orig

export INFILE

#  Set output directory:

outfilbase=nam_${domain}nest_${PDY}${cyc}
cp /meso/save/Geoffrey.Manikin/gempak/s*nam*prm* .

namsnd << EOF > /dev/null
SNBUFR   = $INFILE
SNOUTF   = ${outfilbase}.snd
SFOUTF   = ${outfilbase}.sfc+
SNPRMF   = snnam.prm
SFPRMF   = sfnam.prm
TIMSTN   = 85/2000
r

exit
EOF

/bin/rm *.nts

snd=${outfilbase}.snd
sfc=${outfilbase}.sfc
aux=${outfilbase}.sfc_aux

echo done > $DATA/gembufr_${numdomain}.done
