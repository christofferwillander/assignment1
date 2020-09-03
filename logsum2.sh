#!/bin/bash

USAGE="usage: $0 [-n N] (-c|-2|-r|-F|-t) <filename>"

nrOfFlags=0
nVal=0
nFlag=0
file=0
#flags, on first position is n, if -n exists, the value after is placed in the first place.
declare -a flags
index=0
for arg in $@
do 
    re='^[0-9]+$'
    printf "%s" $arg | grep -q "\-n"
    if [ $? -eq 0 ]; then
        #flag N exists
        nFlag=1
        #echo $nFlag
        index=$((index+1))
        #nVal=$(echo ${flags[index]} | grep -o [1-9][0-9]*)  -z $nVal
        nVal=$(echo $@ | grep -o [1-9][0-9]*)
        #echo "n value is $nVal"
        if [ -z $nVal ]; then     #if the n-flag is not followed by a number
            echo "flag uncomplete"
            exit 1
        fi
        #flags[$index]=$arg
        index=$((index+1))
    elif [ -f $arg ]; then
        file=1
        filename=$arg
        #echo "$arg exist"
    elif ! [[ $arg =~ $re ]]; then
    #else
        flags[$index]=$arg
        index=$((index+1))
    fi
    
done
#echo "all flags ${flags[@]}"
#echo "nflag is $nFlag"
#echo "nVal is $nVal"
#echo "file is $filename"

#check how many parameters, and if the N flag is there.
nrOfFlags=index-1
if [ $nFlag -ne 0 ]; then
    if [ $# -lt 3 ] || [ $# -gt 4 ]; then
        echo $USAGE
        exit 1
	fi
else
    if [ $# -lt 2 ] || [ $# -gt 3 ]; then
		echo $USAGE
		exit 1
	fi
fi
declare -a byteArr
cat $filename > temp.txt
for value in ${flags[@]}
do
    case $value in
        -c)
            cat temp.txt | awk '{print $1}' | sort | uniq -c | sort -k1 -n -r | awk '{print $2 "\t"  $1}' > test.txt
            cp test.txt temp.txt
            ;;
        
        -r)
            cat temp.txt | awk '{print $1 "\t" $9}' | sort -k2 -n -r  > test.txt
            cp test.txt temp.txt
            
            ;;
        -F)
            cat temp.txt | grep "\ [4][0-9][0-9]\ " | awk '{print $1 "\t" $9}' > test.txt
            cp test.txt temp.txt

            ;;
        -2)
            cat temp.txt | grep "\ 2[0-9][0-9]\ " | awk '{print $1}' | sort | uniq -c | sort -k1 -n -r | awk '{print $2 "\t"  $1}' > test.txt
            cp test.txt temp.txt

            ;;

        -t)
            cat temp.txt | awk '{print $1 "\t" $10}' | awk '{array[$1]+=$2} END { for (i in array) {print i "\t" array[i]}}' > test.txt
            cat test.txt | sort -k2 -r -n > temp.txt

            ;;
        *)
            echo "unkown parameter"
            echo ${USAGE}
            exit 1
            ;;
    esac
done

if [ $nFlag -eq 1 ]; then
    cat temp.txt | head -n $nVal
else
    cat temp.txt
fi