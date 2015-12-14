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

if [ $HOSTNAME = 'scherbova.arc.world' ] 
then
   BIN=/smb/system/Scripts/PP-from-mail
else
   BIN=/opt/pp-log/bin
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

if [ $HOSTNAME = 'scherbova.arc.world' ] 
then
   eval $(grep MAILDIR $HOME/.procmailrc)
else
   MAILDIR=/opt/pp-log
fi

XLSX_TEMPL=$BIN/PP-register-original.xlsx

RTF_DIR=$MAILDIR/rtf
RTF_ORG_DIR=$RTF_DIR/01-origin
RTF_WRK_DIR=$RTF_DIR/02-pdf-html-txt
RTF_OUT_DIR=$RTF_DIR/03-out
RTF_FAILED_DIR=$RTF_DIR/98-failed
RTF_ARCH_DIR=$RTF_DIR/99-archive
[ -d $RTF_DIR ] || mkdir -p $RTF_DIR 
[ -d $RTF_ORG_DIR ] || mkdir -p $RTF_ORG_DIR 
[ -d $RTF_WRK_DIR ] || mkdir -p $RTF_WRK_DIR 
[ -d $RTF_OUT_DIR ] || mkdir -p $RTF_OUT_DIR 
[ -d $RTF_FAILED_DIR ] || mkdir -p $RTF_FAILED_DIR 
[ -d $RTF_ARCH_DIR ] || mkdir -p $RTF_ARCH_DIR 

RTF_ORG_FILES=$RTF_ORG_DIR/*.rtf
#RTF_CSV_OUT=$RTF_OUT_DIR/element-$DT.csv 
RTF_CSV_OUT=$RTF_OUT_DIR/element-$YEAR_CSV.csv 
RTF_XLSX_OUT=$RTF_OUT_DIR/PP-element-$DT.xlsx

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
# 1. fetchmail + ( procmail + ripmime )
# destination dir - .procmail MAILDIR=$HOME/automail
#logmsg INFO "Fetch mail"
################################################## 
#$ECHO fetchmail -ak -m "/usr/bin/procmail -d %T"
#rc_fetch=$?
#logmsg $rc_fetch "Fetch mail completed"
#[ $rc_fetch -eq 0 ] || { echo "fetchmail failed. Exit"; exit 123; }

############# RTF #############

# 2. convert rtf to pdf, pdf to html, html to txt
for f in `ls -1 $RTF_ORG_FILES 2>/dev/null`
do
   [ -r $f ] || { logmsg ERROR "$f doesn't exist or I can't read it"; continue; }
   bname=`namename $f`
   PP_NAME=`echo "PP"$bname |sed -r s/_//g`
   printf -v Npp "%04d" ${PP_NAME##*N}
   printf -v doc_prefix "%s" ${PP_NAME%%[0-9]*}
   PP_NAME=${doc_prefix}${Npp}
   # old bname=`namename $f` 
   # old PP_NAME=`echo "PP"$bname |sed -r s/_//g`
   PDF_NAME=$PP_NAME.pdf
   logmsg INFO "Try to convert `basename $f` to $PDF_NAME"
   #$ECHO unoconv -f pdf -o $RTF_WRK_DIR/$PDF_NAME $f
   $ECHO libreoffice --headless --convert-to pdf --outdir $RTF_WRK_DIR $f
   rc_uno=$?
   [ $rc_uno -eq 0 ] || { logmsg $rc_uno "Error while convert $f to $PDF_NAME"; continue; }
   mv -vf $RTF_WRK_DIR/$bname.pdf $RTF_WRK_DIR/$PDF_NAME
   HTML_NAME=$PP_NAME.html
   logmsg INFO "Try to convert $PDF_NAME to $HTML_NAME"
   $ECHO pdf2txt.py -Y exact -t html -o $RTF_WRK_DIR/$HTML_NAME $RTF_WRK_DIR/$PDF_NAME
   rc_html=$?
   [ $rc_html -eq 0 ] || { logmsg $rc_html "Error while convert $PDF_NAME to $HTML_NAME"; continue; }
   RTF_OUT=$PP_NAME-$DT.txt
   logmsg INFO "Try to rip $HTML_NAME to $RTF_OUT"
   $ECHO awk -f $RIP2HTML $RTF_WRK_DIR/$HTML_NAME > $RTF_WRK_DIR/$RTF_OUT
   rc_rip=$?
   [ $rc_rip -eq 0 ] && mv $f $RTF_ARCH_DIR || logmsg $rc_rip "Error while rip $HTML_NAME"
done

# 3. make register for element
for t in  `ls -1 $RTF_WRK_DIR/*-$DT.txt 2>/dev/null`
do
  logmsg INFO "Try to add `basename $t` to register `basename $RTF_CSV_OUT`"
  $ECHO awk -f $MK_REGISTER $t >> $RTF_CSV_OUT
  rc_reg=$?
  [ $rc_reg -eq 0 ] || logmsg $rc_reg "Error while make register from $t"
done

# 4. merge CSV with template 
if [ -r $RTF_CSV_OUT ]
then
   logmsg INFO "Try to merge `basename $RTF_CSV_OUT` and `basename $XLSX_TEMPL` to $RTF_XLSX_OUT"
   $ECHO csv2odf -c \; --input=$RTF_CSV_OUT --template=$XLSX_TEMPL --output=$RTF_XLSX_OUT
   rc_csv=$?
   [ $rc_csv -eq 0 ] || logmsg $rc_csv "Error while merge $RTF_CSV_OUT and $XLSX_TEMPL to $RTF_XLSX_OUT"
   #############   rm -f $RTF_WRK_DIR/*

   # 5. send register vie e-mail 
   logmsg INFO "Try to send e-mail with $RTF_XLSX_OUT to $DST_MAIL"
   [ -r $RTF_XLSX_OUT ] &&  $ECHO mutt -s "Журнал Элемент за $DT" -a $RTF_XLSX_OUT -- $DST_MAIL < /dev/null
   rc_mail=$?
   [ $rc_mail -eq 0 ] || logmsg $rc_mail "Error while sending e-mail with $RTF_XLSX_OUT to $DST_MAIL"
fi

# 6. save failed 
# doesn't work test -f with more than onw file 
# [ -f  $RTF_ORG_FILES ] && mv $RTF_ORG_FILES $RTF_FAILED_DIR 
mv $RTF_ORG_FILES $RTF_FAILED_DIR 

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

# send register vie e-mail 
#logmsg INFO "Try to send e-mail with $XPS_XLSX_OUT to $DST_MAIL"
#[ -r $XPS_XLSX_OUT ] &&  $ECHO mutt -s "Журнал НеоПром за $DT" -a $XPS_XLSX_OUT -- $DST_MAIL < /dev/null
#rc_mail=$?
#[ $rc_mail -eq 0 ] || logmsg $rc_mail "Error while sending e-mail with $XPS_XLSX_OUT to $DST_MAIL"

# save failed 
# doesn't work test -f with more than onw file 
#[ -f  $XPS_ORG_FILES ] && mv $XPS_ORG_FILES $XPS_FAILED_DIR 
mv $XPS_ORG_FILES $XPS_FAILED_DIR 

logmsg INFO "FINISH"

