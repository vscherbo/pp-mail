BEGIN { Nmax=4; Nprev=0 }
{
if ( Nprev == Nmax ) for (i=1;i<Nmax;i++) Prev[i]=Prev[i+1]
else Nprev++
Prev[Nprev]=$0
}
# Дата
# ПП№
/ПЛАТЕЖНОЕ ПОРУЧЕНИЕ/ { PPnum=$4; if ("" != $5) Date=$5 }
/ПЛАТЕЖ НОЕ ПОРУЧЕНИЕ/ { PPnum=$5; if ("" != $6) Date=$6 }
/электронно/ { if ("" != $1) { split($1,ar,".") ; Date=ar[3]"."ar[2]"."ar[1] } }
# поле с текщем годом - Date, PPnum - предыдущее
# или если есть "ПЛАТЕ... ПОРУЧЕНИЕ" с любым количеством пробелов, то PPnum=$(NF-1); Date=$NF
# если есть "лектронно", то PPnum=$(NF-2); Date=$(NF-1)
#/ПЛАТЕЖ НОЕ ПОРУЧЕНИЕ/ { PPnum=$5; Date=$6 }

# Контрагент: строка n-3 относительно строки "Получатель"
/Получатель/ {
Contragent=Prev[1]
gsub(/^[ ]+/, "", Contragent)
delete Prev
Nprev=0 
}
# Сумма последнее поле:
# приводим форматы 9999= и 9999-99 к формату 9999.99 для csv2odf
#ИНН 7806419760 КПП С умма 1 0250=
/ИНН.*КПП.*С[[:space:]]*умма/ { 
gsub(/=/, "-00", $NF)
# prev! sum_str=gensub(/(^.*умма)([[:digit:]]+)[[:space:]]*([[:digit:]]+)/, "\\2\\3", "g")
sum_str=gensub(/(^.*умма[[:space:]]*)([[:digit:]]+)[[:space:]]*([[:digit:]]+)/, "\\2\\3", "g")
Sum=gensub(/([[:digit:]])-([[:digit:]])/, "\\1.\\2", "g", sum_str)
#Sum=gensub(/([[:digit:]])-([[:digit:]])/, "\\1.\\2", "g", $NF)
}
# Плательщик
/ООО "Элемент"/ {Payer="ООО \"Элемент\""}
/ООО "НОВА-СЕРВИС"/   {Payer="ООО \"НОВА-СЕРВИС\""}
# Назначение платежа: строки n-3,n-2,n-1 относительно строки "Назначение платежа"
/Назначение платежа/ {
Target=Prev[1]""Prev[2]""Prev[3]
gsub(/^[ ]+/, "", Target)
delete Prev
Nprev=0 
}

END {
printf "%s;%s;%s;-%s;%s;%s;\"\"\n", Date,PPnum,Contragent,Sum,Payer,Target
}
