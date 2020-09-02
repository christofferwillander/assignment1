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
    if [ -f $arg ]; then
        file=1
        filename=$arg
        echo "file exist"  
    else
        flags[$index]=$arg
        ((index=index+1))
    fi
    
done
echo ${flags[@]}
echo ${flags[1]}

#check all flags
index=0
for flag in ${flags[@]}
do
    
    printf "%s" $flag | grep -q "N\|\-n"
    if [ $? -eq 0 ]; then
        #flag N exists
        nFlag=1
        ((index=index+1))
        nVal=$(echo ${flags[index]} | grep -o [1-9][0-9]*) 
        #echo $nVal
        if [ -z "$nVal" ]; then 	#if the n-flag is not followed by a number
            echo "flag uncomplete"
            exit 1
        fi
    fi
    ((index=index+1))
done

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

for value in ${flags[@]}
do
    case $value in
        -c)
            res=$(cat $filename | awk '{print $1}' | sort | uniq -c | sort -k1 -n -r | awk '{print $2 "\t"  $1}')
            ;;
        
        -n)
            
            ;;
        *)
            echo "unkown parameter"
            echo ${USAGE}
            exit 1
            ;;
    esac
done