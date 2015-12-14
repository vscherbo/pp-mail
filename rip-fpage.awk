BEGIN {RS=">"}
BEGIN { FS="(=\"|\" )" }
/Glyphs.*UnicodeString/ { 
#for (i = 1; i <= NF; i++) {
#    printf("$%d = {%s}\n", i, $i)
#}
Xcoord=0; Ycoord=0; FontSize=0; Indices=""; UnicodeString=""
for (f=1;f<=NF;f++) {
  if ( $f ~ "OriginX" ) Xcoord=$(f+1)
  if ( $f ~ "OriginY" ) Ycoord=$(f+1)
  if ( $f ~ "FontRenderingEmSize" ) FontSize=$(f+1)
  if ( $f ~ "Indices" ) Indices=$(f+1)
  if ( $f ~ "UnicodeString" ) UnicodeString=$(f+1)
}
  Ycoord=int(Ycoord-FontSize)
  gsub (/\xc2\xa0/, " ", UnicodeString)
  #gsub (/^[ ]+|[ ]+$/, "", UnicodeString)
  gsub (/&quot;/, "\"", UnicodeString)
  gsub (/&amp;/, "\\&", UnicodeString)

### printf "x=%s, y=%s, FontSize=%s, Ind=%s, UnStr=}%s{\n",  Xcoord, Ycoord, FontSize, Indices, UnicodeString


  Nind=split(Indices, indarr, ";")
  Nchars=split(UnicodeString, unarr,"")
  if ( Nind != Nchars) {
   printf "NOT equal count Chars(%s) and Indices(%s), str=%s\n", Nchars, Nind, UnicodeString
   printf "x=%s, y=%s, FontSize=%s, Ind=%s, UnStr=%s\n",  Xcoord, Ycoord, FontSize, Indices, UnicodeString
   # print Xcoord, Ycoord, FontSize, Indices, UnicodeString
   Nind=0
  }
  delete Space
  for (i=1;i<=Nind;i++) {
     Nx=split(indarr[i],Xarr,",")
     if ( Nx > 1 ) {
        Space[i]=int(Xarr[2]/FontSize/FontSize)
        ### print "N="Nx", Delta="Space[i]
     }
  }
  Xspace=int(2*Xcoord/13+0.1)
  ###### Yspace=int(Ycoord/FontSize)
  Str=""
  ### printf "Xspace=%s\n", Xspace
  #for (x=1;x<=Xspace;x++) Str=Str" "
  for (c=1;c<=Nchars;c++) {
      SpaceStr=""
      if ( Space[c] > 0 ) {
        ### printf "FontSize=%s, SpaceNum=%s\n", FontSize, Space[c]
        for (s=1;s<=Space[c];s++) SpaceStr=SpaceStr" "
      } 
      #Str=Str""SpaceStr""unarr[c]
      Str=Str""unarr[c]""SpaceStr
  }
   ### printf "Xspace=%s, Yspace=%s, >%s<\n", Xspace, Yspace, Str
   ### printf ">%s<\n", Str
  if ( 0 == length(Str) ) next

  if (Ycoord+1 in arr_Y) Ycoord=Ycoord+1
  if (Ycoord+2 in arr_Y) Ycoord=Ycoord+2
  if (Ycoord+3 in arr_Y) Ycoord=Ycoord+3
  if (Ycoord-1 in arr_Y) Ycoord=Ycoord-1
  if (Ycoord-2 in arr_Y) Ycoord=Ycoord-2
  if (Ycoord-3 in arr_Y) Ycoord=Ycoord-3
### printf ">>%s<<\n", Str
  #Attrs[Ycoord,Xcoord]=Str
  #arr_Y[Ycoord]=1
  Attrs[Ycoord,Xspace]=Str
  arr_Y[Ycoord]=1
}

END {
for (dbl in Attrs) {
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
      #if ( "" != Attrs[tops[t],lefts[l]] && " " != Attrs[tops[t],lefts[l]] ) {
      if ( "" != Attrs[tops[t],lefts[l]] ) {
         leftSpace=lefts[l]-length(row)
### printf "leftSpace=(%s-%s)=%s\n",  lefts[l], length(row), leftSpace
### printf "Attr=>%s<\n", Attrs[tops[t],lefts[l]]
         SpaceStr=""
         for (s=1;s<=leftSpace;s++) SpaceStr=SpaceStr" "
         row=row""SpaceStr""Attrs[tops[t],lefts[l]]
      }
   }
   ### gsub(/&quot;/, "\"", row)
   ### printf "%s=%s\n", ind_str, row
   print row
}

}

