#!/bin/bash

printResult() {
if [ $numberOfResults -gt 0 ]; then
	command=$@
	command+=" | head -n $numberOfResults"
	eval $command
else
	eval $@
fi
exit 0
}

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

# Cleaning up in the parameter array
unset params[$(($#-1))]
params=("${params[@]}")

# Checking whether -n flag is used
printf "%s" $@ | grep -q "\-n"
if [ $? -eq 0 ]; then
	echo "Parameter -n is present"
	nFlag=1
else
	echo "Parameter -n is not present"
	nFlag=0
fi

# If the -n parameter is present - check for N argument
if [ $nFlag -eq 1 ]; then
for index in "${!params[@]}"; do
   if [[ "${params[$index]}" = "-n" ]]; then
	# Updating index to point at next element in array - after -n parameter (should be a number)
        index=$((index+1))
	# Storing result in numberOfResults
	numberOfResults=$(echo ${params[$index]} | grep ^[1-9][0-9]*)
	# Cleaning up in the parameter array
	unset params[$index]
	unset params[$((index-1))]
	params=("${params[@]}")
   fi
done

if [ -z "$numberOfResults" ]; then
	echo "ERROR: Incorrect or missing argument N to -n parameter"
	echo ${USAGE}
	exit 1
fi
fi

for param in ${params[@]}
do
    case $param in
	-c)
		var="awk '{print \$1}' $fileName | sort | uniq -c | sort -k1 -n -r | awk '{print \$2 \"\t\" \$1}'"
	 	printResult $var
	    ;;
	 *)
            echo "ERROR: Unknown parameter $param used"
            echo ${USAGE}
            exit 1
            ;;
    esac
done
