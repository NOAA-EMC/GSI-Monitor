function name(arg)
*
* run dt variable scale base
*
d=subwrd(arg,1)
b=subwrd(arg,2)

if (d = '' | d = 'def')
   exit 0
endif
if (b = '' | b = 'def')
  'set cint ' d
   exit 0
endif


i=-6
if (b != 0)
  i=-5
endif
line='set clevs '
while(i <= 6)
  if (b != 0)
     line=line ' ' i*d+b
  endif
  if (b = 0 & i != 0)
     line=line ' ' i*d+b
  endif
  i=i+1
endwhile

line
'set ccols  9 14 4 11 5 3 99 7 12 8 2 27 6'
return
endfile
