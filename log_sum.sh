#!/bin/bash
blacklistPrint()
{
	dig -f dns.blacklist.txt +short > dnsFile.txt
	grep -f dnsFile.txt blacklistCheck > tempIP

	#make conditions, if -F or -r flag exist, the IP address will be placed in the second column.
	if [ $? -eq 0 ] && [ $oddFlag -eq 1 ]; then
		join blacklistCheck tempIP | awk '{ if (($2==$3)) printf("%s\t %s\t %s\n", $1, $2, "*blacklisteed*"); else printf("%s\t %s\n", $1, $2) }'
	elif [ $? -eq 0 ]; then
		join blacklistCheck tempIP | awk '{ if (($1==$3)) printf("%s\t %s\t %s\n", $1, $2, "*blacklisteed*"); else printf("%s\t %s\n", $1, $2) }'
	else #if there were no matches
		cat blacklistCheck
	fi

	rm dnsFile.txt
	rm tempIP
	rm blacklistCheck

}

printResult()
{
	command=$@
	if [[ $numberOfResults -gt 0 ]]; then
		if [ $eFlag -eq 1 ]; then
			#resolve domain addresses.
			command+=" | head -n $numberOfResults"
			eval $command > blacklistCheck
			blacklistPrint $command

		else
			command+=" | head -n $numberOfResults"
			eval $command
		fi
	elif [ $eFlag -eq 1 ]; then
		#resolve addresses
		echo "haaaaaaj"
		eval $command > blacklistCheck
		blacklistPrint $command
	else
		eval $@
	fi
	exit 0
}

# Showing proper script usage to user
USAGE="Usage: $0 [-n N] (-c|-2|-r|-F|-t) [-e] <filename>"

if [ $# -lt 1 ] || [ $# -gt 5 ]; then
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
	nFlag=1
else
	nFlag=0
fi


# Checking whether -F or -r flag is used
printf "%s" $@ | grep -q "\-F\|\-r"
if [ $? -eq 0 ]; then
	oddFlag=1
else
	oddFlag=0
fi

# Checking whether -e flag is used
printf "%s" $@ | grep -q "\-e"
if [ $? -eq 0 ]; then
	eFlag=1

	# Cleaning up in the parameter array
	index=$#
	index=$((index-2))
	unset params[$index]
	params=("${params[@]}")
else
	eFlag=0
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

# Check for number of parameters - taking into considerations which flags are being used
if [[ $eFlag -eq 1 && $nFlag -eq 1 && $# -lt 5  ]] || [[ $nFlag -eq 1 && $# -lt 4  ]] || [[ $eFlag -eq 1 && $# -lt 3  ]] || [ $# -eq 1 ]; then
	echo "ERROR: Incorrect number of parameters used"
	echo ${USAGE}
	exit 1
fi


for param in ${params[@]}
do
    case $param in
	-c)
		var="awk '{print \$1}' $fileName | sort | uniq -c | sort -k1 -n -r | awk '{print \$2 \"\t\" \$1}'"
	 	printResult $var
	    ;;
	-r)
            var="awk '{print \$9 \"\t\" \$1}' $fileName | sort -k2 -n -r"
            printResult $var
	    ;;
	-F)
            var="grep '\ [45][0-9][0-9]\ ' $fileName | awk '{print \$9 \"\t\" \$1}' | sort -k1 -n -r"
            printResult $var
            ;;
	-2)
            var="grep '\ 2[0-9][0-9]\ ' $fileName | awk '{print \$1}' | sort | uniq -c | sort -k1 -n -r | awk '{print \$2 \"\t\"  \$1}'"
            printResult $var
            ;;

	-t)
		var="awk '{print \$1 \"\t\" \$10}' $fileName | awk '{array[\$1]+=\$2} END { for (i in array) {print i \"\t\" array[i]}}' | sort -k2 -r -n"
		printResult $var
		;;
	 *)
            echo "ERROR: Unknown parameter $param used"
            echo ${USAGE}
            exit 1
            ;;
    esac
done