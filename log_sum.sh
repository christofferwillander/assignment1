#!/bin/bash

USAGE="usage: $0 [-n N] (-c|-2|-r|-F|-t) <filename>"

nrOfFlags=0
nVal=0
ite=0


printf "%s" $@ | grep -q "N\|\-n"
if [ $? -eq 0 ]; then
	#if [ $? -eq "N" ]; then
		#$((nrOfFlags=nrOfFlags+1))
		#will not be detected in the other function, does not have -
	#fi
	nVal=$(echo $@ | grep -o [1-9][0-9]*) 
	#echo $nVal
	if [ -z "$nVal" ]; then 	#if the n-flag is not followed by a number
		echo "flag uncomplete"
		exit 1
	fi
fi 
echo $nVal
if [ $nVal -n 0 ]; then
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


echo $1 | grep -q "-"
if [ $? -eq 0 ]; then
	nrOfFlags=1
	echo "Found flag"  
	echo $nrOfFlags
else 
	echo "error"
	exit 1
fi
check=0
echo $2 | grep -q "-"
if [ $? -eq 0 ]; then
        nrOfFlags=2 
        echo "Found flag"
elif [ -f $2 ]; then
	echo "$2 exists."
	check=1
else
	echo "error"
	exit 1
fi

if [ $check -eq 0 ]; then
	if [ $nrOfFlags -eq 2 ]; then
		if [ -f $3 ]; then
			echo "$3 exists."
		else
			echo "$3 does not exist."
		fi
	else
		echo "file does not exist"
		exit 1
	fi
fi


case $1 in
	-c)
		if [ $nrOfFlags -eq 2 ]; then
			cat $3 | awk '{print $1}' | sort | uniq -c | sort -k1 -n -r | awk '{print $2 "\t"  $1}'
		else
			cat $2 | awk '{print $1}' | sort | uniq -c | sort -k1 -n -r | awk '{print $2 "\t"  $1}'

		fi
		;;

	*)
		echo "unkown parameter"
		echo ${USAGE}
		exit 1
		;;
esac