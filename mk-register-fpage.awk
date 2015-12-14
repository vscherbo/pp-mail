BEGIN { Nmax=4; Nprev=0 }
{
if ( Nprev == Nmax ) for (i=1;i<Nmax;i++) Prev[i]=Prev[i+1]
else Nprev++
Prev[Nprev]=$0
}
# Дата
# ПП№
/ПЛАТЕЖНОЕ ПОРУЧЕНИЕ/ {Date=$5; PPnum=$4 }
# Контрагент: строка n-3 относительно строки "Получатель"
/Получатель/ {
Contragent=Prev[1]
gsub(/ " /, "\"", Contragent)
gsub(/ "$/, "\"", Contragent)
delete Prev
Nprev=0 
}
# Сумма все поля после слова "Сумма":
# приводим форматы 9999= и 9999-99 к формату 9999.99 для csv2odf
/ИНН.*КПП.*Сумма/ { 
for (f=1;f<=NF;f++) if ( $f ~ /Сумма/ ) SumStart=f+1
for (f=SumStart;f<=NF;f++) SumStr=SumStr""$f
gsub(/=/, "-00", SumStr)
Sum=gensub(/([[:digit:]])-([[:digit:]])/, "\\1.\\2", "g", SumStr)
}
# Плательщик
/НеоПром/ {Payer="ООО \"НеоПром\""}
/Серенада/ {Payer="ООО \"Серенада\""}
/Элемент/ {Payer="ООО \"Элемент\""}
/КИП СПБ/ {Payer="ООО \"КИП СПБ\""}
/Энергосервис/ {Payer="ООО \"ТД Энергосервис\""}
# Назначение платежа: строки n-3,n-2,n-1 относительно строки "Назначение платежа"
/Назначение платежа/ {
Target=Prev[1]""Prev[2]""Prev[3]
gsub(/^[ ]+/, "", Target)
gsub(/  /, " ", Target)
delete Prev
Nprev=0 
}

END {
gsub (/^[ ]+|[ ]+$/, "", Date)
gsub (/^[ ]+|[ ]+$/, "", PPnum)
gsub (/^[ ]+|[ ]+$/, "", Contragent)
gsub (/^[ ]+|[ ]+$/, "", Sum)
gsub (/^[ ]+|[ ]+$/, "", Payer)
gsub (/^[ ]+|[ ]+$/, "", Target)
printf "%s;%s;%s;-%s;%s;%s;\"\"\n", Date,PPnum,Contragent,Sum,Payer,Target
}
