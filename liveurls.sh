#!/bin/bash
input="all-urls.txt"
while IFS= read -r line
do
  #echo "$line"
    status_code=`curl --max-time 5 -s -o /dev/null -w "%{http_code}" $line`
    echo "$line ":" $status_code"
    echo -e "$line":"$status_code\n" >> all-urls-output.txt
done < "$input"