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
MK_REGISTER=$BIN/mk-register.awk

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
PDF_CSV_OUT=$PDF_OUT_DIR/element-$YEAR_CSV.csv 
PDF_XLSX_OUT=$PDF_OUT_DIR/PP-element-$DT.xlsx

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

# 2. make register for element
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
   logmsg INFO "Try to merge `basename $PDF_CSV_OUT` and `basename $XLSX_TEMPL` to $PDF_XLSX_OUT"
   $ECHO csv2odf -c \; --input=$PDF_CSV_OUT --template=$XLSX_TEMPL --output=$PDF_XLSX_OUT
   rc_csv=$?
   [ $rc_csv -eq 0 ] || logmsg $rc_csv "Error while merge $PDF_CSV_OUT and $XLSX_TEMPL to $PDF_XLSX_OUT"
   #############   rm -f $PDF_WRK_DIR/*

   # 5. send register vie e-mail 
   logmsg INFO "Try to send e-mail with $PDF_XLSX_OUT to $DST_MAIL"
####################################################################
###############   [ -r $PDF_XLSX_OUT ] &&  $ECHO mutt -s "Журнал Элемент за $DT" -a $PDF_XLSX_OUT -- $DST_MAIL < /dev/null
####################################################################
   rc_mail=$?
   [ $rc_mail -eq 0 ] || logmsg $rc_mail "Error while sending e-mail with $PDF_XLSX_OUT to $DST_MAIL"
fi

# 4. save failed 
# doesn't work test -f with more than onw file 
# [ -f  $PDF_ORG_FILES ] && mv $PDF_ORG_FILES $PDF_FAILED_DIR 
mv $PDF_ORG_FILES $PDF_FAILED_DIR 


logmsg INFO "FINISH"

