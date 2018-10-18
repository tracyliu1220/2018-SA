ls -ARl | grep "^[-d]" | sort -k 5 -rn | awk 'BEGIN {file=0; dirn=0; total=0} { if( $1 ~ "^-") {file ++; total+=$5} } { if( $1 ~ "^d") {dirn++; total+=$5} } NR<=5 {print NR ":" $5 " " $9} END {print "Dir num: " dirn "\nFile num: " file "\nTotal: " total}'

