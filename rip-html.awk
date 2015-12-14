# input file created as: 
# 1. unoconv -f pdf -o PP#571.pdf PP#571.rtf
# 2. pdf2txt.py -Y exact -t html -o PP#571-Y-exact.html PP#571.pdf

# ignore border
/border/ {getline}
/span/ { Narr=split($0, arr, "[><]");
split(arr[2], coord, ";")
left=coord[3]
top=coord[4]
font_size=coord[5]
gsub(/[^[:digit:]]/, "", left)

gsub(/[^[:digit:]]/, "", top)
if (top+1 in arr_top) top=top+1
if (top+2 in arr_top) top=top+2
if (top+3 in arr_top) top=top+3
if (top+4 in arr_top) top=top+4
if (top-1 in arr_top) top=top-1
if (top-2 in arr_top) top=top-2
if (top-3 in arr_top) top=top-3
if (top-4 in arr_top) top=top-4

gsub(/[^[:digit:]]/, "", font_size)
font_width=(font_size/2)+3; # +3 - эмпирически

ppletter=arr[3]
delim=""
if ( left-arr_left_prev[top] > font_width ) delim=" "
### debug
#if ( 491 == top ) printf "left-prev=%d-%d =delta=%d >f_wifth=%d, delim=%s, letter=%s\n", left, arr_left_prev[top], left-arr_left_prev[top], font_width, delim, ppletter
###
Rows[top,left]=Rows[top,left]""delim""ppletter
arr_left_prev[top]=left
arr_top[top]=1
}



END { 

i=1
for (dbl in Rows) {
   split(dbl,inds,SUBSEP)
   ind1[i]=inds[1]
   ind2[i]=inds[2]
   dual[i]=inds1":"inds2
#print inds[1]"-"inds[2]
   i++
}
#print "ind1"
#for (i in ind1) print ind1[i]

Ntop=asort(ind1,tops)
Nleft=asort(ind2,lefts)
#print "Tops"
#for (i=1;i<=Ntop;i++) print tops[i]

#Compact inds
top_prev=""
for (t=1;t<=Ntop;t++) {
    if ( top_prev == tops[t] ) 
       delete tops[t] 
   else 
       top_prev=tops[t]
}

left_prev=""
for (l=1;l<=Nleft;l++) {
    if ( left_prev == lefts[l] ) 
       delete lefts[l] 
    else 
       left_prev=lefts[l]
}

for (t=1;t<=Ntop;t++) {
   if ( "" == tops[t] ) continue
   #printf "Top=%s\n", tops[t]
   ind_str=tops[t]
   row=""
   for (l=1;l<=Nleft;l++) {
      if ( "" == lefts[l] ) continue
      if ( "" != Rows[tops[t],lefts[l]] ) {
         row=row""Rows[tops[t],lefts[l]]
      }
   }
   gsub(/&quot;/, "\"", row)
   ### printf "%s=%s\n", ind_str, row
   print row
}

}
