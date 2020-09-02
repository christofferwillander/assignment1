#!/bin/bash
		
# Showing proper script usage to user
USAGE="Usage: $0 [-n N] (-c|-2|-r|-F|-t) <filename>"

if [ $# -lt 1 ] || [ $# -gt 4 ]; then
	echo $USAGE
	exit 1
fi

# Iterating through all parameters - inserting into params array

declare -a params
for param in "$@"
do
    params+=($param)
done

# Checking if a file with the given name exists

fileName=${params[-1]}
test -f $fileName

# Checking return value of test function
if [ $? -eq 1 ]; then
	echo "ERROR: File $fileName does not exist"
	exit 1
fi

# Checking whether -n flag is used
printf "%s" $@ | grep -q "\-n"
if [ $? -eq 0 ]; then
	echo "Parameter -n is present"
	nFlag=1
else
	echo "Parameter -n is not present"
	nFlag=0
fi

if [ $nFlag -eq 1 ]; then
for index in "${!params[@]}"; do
   if [[ "${params[$index]}" = "-n" ]]; then
        index=$((index+1))
	echo $index
	numberOfResults=$(echo ${params[$index]} | grep ^[1-9][0-9]*)
   fi
done
fi

for param in ${params[@]}
do
    case $param in
        -c)
            if [ $numberOfResults -gt 0 ]; then
		awk '{print $1}' $fileName | sort | uniq -c | sort -k1 -n -r | awk '{print $2 "\t"  $1}' | head -n $numberOfResults
	    else
		awk '{print $1}' $fileName | sort | uniq -c | sort -k1 -n -r | awk '{print $2 "\t"  $1}'
	    fi
	    exit 0
	    ;;
	-n) 
            ;;
	 *)
            echo "ERROR: Unknown parameter used"
            echo ${USAGE}
            exit 1
            ;;
    esac
done
