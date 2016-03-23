#!/bin/sh

. $HOME/.bash_profile
. /usr/local/bin/bashlib

#debug
#ECHO=echo

export LANG=en_US.UTF-8
[ $LANG = 'en_US.UTF-8' ] || { echo "Error: LANG must be en_US.UTF-8"; exit 255; }

##########################
# set this variables!    #
##########################

if [ $HOSTNAME = 'scherbova.arc.world' -o $HOSTNAME = 'scherbova' ] 
then
   BIN=/smb/system/Scripts/PP-from-mail/devel
   #eval $(grep MAILDIR $HOME/.procmailrc)
   MAILDIR=`dirname $0`
else
   BIN=/opt/pp-log/bin
   MAILDIR=/opt/pp-log
fi
RIP2HTML=$BIN/rip-html.awk
#MK_REGISTER=$BIN/mk-register.awk
MK_REGISTER=$BIN/mk-register-neoprom.awk

DST_MAIL=pp-element@kipspb.ru 
#DST_MAIL=it-events@arc.world 

DT=`date +%F_%H%M%S`
YEAR_CSV=`date +%Y`

# широкие буквы
# Д, Ж, М, Ф, Ш, Щ, Ы, Ю

RIP2FPAGE=$BIN/rip-fpage.awk
MK_REGISTER_FPAGE=$BIN/mk-register-fpage.awk

XLSX_TEMPL=$BIN/PP-register-original.xlsx

PDF_DIR=$MAILDIR/pdf
PDF_ORG_DIR=$PDF_DIR/01-origin
PDF_WRK_DIR=$PDF_DIR/02-html-txt
PDF_OUT_DIR=$PDF_DIR/03-out
PDF_FAILED_DIR=$PDF_DIR/98-failed
PDF_ARCH_DIR=$PDF_DIR/99-archive
[ -d $PDF_DIR ] || mkdir -p $PDF_DIR 
[ -d $PDF_ORG_DIR ] || mkdir -p $PDF_ORG_DIR 
[ -d $PDF_WRK_DIR ] || mkdir -p $PDF_WRK_DIR 
[ -d $PDF_OUT_DIR ] || mkdir -p $PDF_OUT_DIR 
[ -d $PDF_FAILED_DIR ] || mkdir -p $PDF_FAILED_DIR 
[ -d $PDF_ARCH_DIR ] || mkdir -p $PDF_ARCH_DIR 

PDF_ORG_FILES=$PDF_ORG_DIR/*.pdf
PDF_CSV_OUT=$PDF_OUT_DIR/nova-service-$YEAR_CSV.csv
PDF_XLSX_OUT=$PDF_OUT_DIR/PP-nova-service-$DT.xlsx

XPS_DIR=$MAILDIR/xps
XPS_ORG_DIR=$XPS_DIR/01-origin
XPS_WRK_DIR=$XPS_DIR/02-fpage-txt
XPS_OUT_DIR=$XPS_DIR/03-out
XPS_FAILED_DIR=$XPS_DIR/98-failed
XPS_ARCH_DIR=$XPS_DIR/99-archive
[ -d $XPS_DIR ] || mkdir -p $XPS_DIR
[ -d $XPS_ORG_DIR ] || mkdir -p $XPS_ORG_DIR
[ -d $XPS_WRK_DIR ] || mkdir -p $XPS_WRK_DIR
[ -d $XPS_OUT_DIR ] || mkdir -p $XPS_OUT_DIR
[ -d $XPS_FAILED_DIR ] || mkdir -p $XPS_FAILED_DIR
[ -d $XPS_ARCH_DIR ] || mkdir -p $XPS_ARCH_DIR
XPS_ORG_FILES=$XPS_ORG_DIR/*.xps
#XPS_CSV_OUT=$XPS_OUT_DIR/neoprom-$DT.csv 
XPS_CSV_OUT=$XPS_OUT_DIR/neoprom-$YEAR_CSV.csv
XPS_XLSX_OUT=$XPS_OUT_DIR/PP-neoprom-$DT.xlsx


LOG=$MAILDIR/`namename $0`-$DT.log
exec 1>$LOG 2>&1
set -vx # DEBUG only
############# PDF #############

# 1. pdf to html, html to txt
for f in `ls -1 $PDF_ORG_FILES 2>/dev/null`
do
   [ -r $f ] || { logmsg ERROR "$f doesn't exist or I can't read it"; continue; }
   bname=`namename $f`
   PDF_NAME=$f
   PP_NAME=$bname

   HTML_NAME=$PP_NAME.html
   logmsg INFO "Try to convert $PDF_NAME to $HTML_NAME"
   $ECHO pdf2txt.py -Y exact -t html -o $PDF_WRK_DIR/$HTML_NAME $PDF_NAME
   rc_html=$?
   [ $rc_html -eq 0 ] || { logmsg $rc_html "Error while convert $PDF_NAME to $HTML_NAME"; continue; }
   PDF_OUT=$PP_NAME-$DT.txt
   logmsg INFO "Try to rip $HTML_NAME to $PDF_OUT"
   $ECHO awk -f $RIP2HTML $PDF_WRK_DIR/$HTML_NAME > $PDF_WRK_DIR/$PDF_OUT
   rc_rip=$?
   [ $rc_rip -eq 0 ] && mv $f $PDF_ARCH_DIR || logmsg $rc_rip "Error while rip $HTML_NAME"
done

# 2. make register for nova-service
for t in  `ls -1 $PDF_WRK_DIR/*-$DT.txt 2>/dev/null`
do
  logmsg INFO "Try to add `basename $t` to register `basename $PDF_CSV_OUT`"
  $ECHO awk -f $MK_REGISTER $t >> $PDF_CSV_OUT
  rc_reg=$?
  [ $rc_reg -eq 0 ] || logmsg $rc_reg "Error while make register from $t"
done

# 3. merge CSV with template 
if [ -r $PDF_CSV_OUT ]
then
   logmsg INFO "Try to sort `basename $PDF_CSV_OUT`"
   sort -n -t";" -k2 $PDF_CSV_OUT > /tmp/csv.sorted
   logmsg $? "Sort $PDF_CSV_OUT completed"
   mv /tmp/csv.sorted $PDF_CSV_OUT
   logmsg INFO "Try to merge `basename $PDF_CSV_OUT` and `basename $XLSX_TEMPL` to $PDF_XLSX_OUT"
   $ECHO csv2odf -c \; --input=$PDF_CSV_OUT --template=$XLSX_TEMPL --output=$PDF_XLSX_OUT
   rc_csv=$?
   [ $rc_csv -eq 0 ] || logmsg $rc_csv "Error while merge $PDF_CSV_OUT and $XLSX_TEMPL to $PDF_XLSX_OUT"
   #############   rm -f $PDF_WRK_DIR/*

   # 5. send register vie e-mail 
   logmsg INFO "Try to send e-mail with $PDF_XLSX_OUT to $DST_MAIL"
####################################################################
###############   [ -r $PDF_XLSX_OUT ] &&  $ECHO mutt -s "Журнал Нова-Сервис за $DT" -a $PDF_XLSX_OUT -- $DST_MAIL < /dev/null
####################################################################
   rc_mail=$?
   [ $rc_mail -eq 0 ] || logmsg $rc_mail "Error while sending e-mail with $PDF_XLSX_OUT to $DST_MAIL"
fi

# 4. save failed 
# doesn't work test -f with more than onw file 
# [ -f  $PDF_ORG_FILES ] && mv $PDF_ORG_FILES $PDF_FAILED_DIR 
mv $PDF_ORG_FILES $PDF_FAILED_DIR 

############# XPS #############

pushd $XPS_WRK_DIR
for x in `ls $XPS_ORG_FILES 2>/dev/null`
do
   xpp=`namename $x`
   mkdir $xpp
   pushd $xpp
     unzip $x
     rc_unzip=$?
   popd
   logmsg INFO "Try to unzip $x"
   [ $rc_unzip -eq 0 ] || { logmsg $rc_unzip "Error while unzip $x"; continue; }
   fpage=$xpp/Documents/1/Pages/1.fpage
   logmsg INFO "Try to read $fpage"
   [ -r $fpage ] || { logmsg ERROR "$fpage doesn't exist or I can't read it"; continue; }
   $ECHO awk -f $RIP2FPAGE $fpage > $xpp-$DT.txt
   rc_neorip=$?
   [ $rc_neorip -eq 0 ] || { logmsg $rc_neorip "Error while rip $fpage"; continue; }
   $ECHO awk -f $MK_REGISTER_FPAGE $xpp-$DT.txt >> $XPS_CSV_OUT
   rc_mkreg=$?
   [ $rc_mkreg -eq 0 ] && mv $x $XPS_ARCH_DIR || logmsg $rc_mkreg "Error while add $xpp-$DT.txt to register"
done
popd

# merge CSV with template 
logmsg INFO "Try to merge `basename $XPS_CSV_OUT` and `basename $XLSX_TEMPL` to $XPS_XLSX_OUT"
$ECHO csv2odf -c \; --input=$XPS_CSV_OUT --template=$XLSX_TEMPL --output=$XPS_XLSX_OUT
rc_csv=$?
[ $rc_csv -eq 0 ] || logmsg $rc_csv "Error while merge $XPS_CSV_OUT and $XLSX_TEMPL to $XPS_XLSX_OUT"
#$ECHO rm -rf $XPS_WRK_DIR/*
#$ECHO rm -f $XPS_CSV_OUT



logmsg INFO "FINISH"

