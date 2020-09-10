
#!/bin/bash
errorCodesSpecialCase() {
command=$@
command+=" > specialCase.txt"
eval $command
ctr=0
curErrorCode=$(awk '{print $1}' specialCase.txt | head -n 1 | grep -Eo "[0-9]{3}")
while IFS= read -r line
do
nextErrorCode=$(echo $line | awk '{print $1}' | grep -Eo "[0-9]{3}")
if [[ $ctr -lt $numberOfResults && $curErrorCode == $nextErrorCode ]]; then
ctr=$((ctr+1))
curErrorCode=$nextErrorCode
if [[ eFlag -eq 0 ]]; then
echo $line
else
echo $line >> blacklistComparison.txt
fi
elif [[ $nextErrorCode != $curErrorCode ]]; then
ctr=1
curErrorCode=$nextErrorCode
if [[ eFlag -eq 0 ]]; then
echo $line
else
echo $line >> blacklistComparison.txt
fi
fi
done < specialCase.txt
if [[ eFlag -eq 1 ]]; then
blacklistCheck
fi
rm specialCase.txt
}
checkNumOfFuncParams() {
# Removing current function flag from parameter array
unset params[0]
params=("${params[@]}")
# Checking if function parameter is repeated more than once (if so - print error message and exit)
if [[ "$1" = "${params[0]}" ]]; then
echo "ERROR: Too many function parameters set, command $1 is repeated more than once"
echo ${USAGE}
exit 1
# Checking if there are still function flags left in parameter array (if so - print error message and exit)
elif [[ ${#params[@]} -gt 0 ]]; then
echo "ERROR: Too many function parameters set, $1 cannot be combined with ${params[0]}"
echo ${USAGE}
exit 1
fi
}
blacklistCheck() {
# Checking if DNS blacklist file exists
blacklistFile="dns.blacklist.txt"
test -f $blacklistFile
# If DNS blacklist file does not exist - terminate, check for matches in resolved IP list
if [[ $? -eq 1 ]]; then
echo "ERROR: Blacklist file $blacklistFile does not exist"
rm blacklistComparison.txt
exit 1
else
# Resolve IP addresses for domain names in DNS blacklist - save in resolved.txt
dig -f $blacklistFile +short > resolved.txt
# Iterate through blacklistComparison.txt - check for matches (compare with resolved.txt)
while IFS= read -r line
do
curIP=$(echo "$line" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
grep -F -q "$curIP" resolved.txt
# If match was found (blacklisted IP) - print line with *Blacklisted!*, else print line as is
if [[ $? -eq 0 ]]; then
echo "$line *Blacklisted!*"
else
echo "$line"
fi
done < blacklistComparison.txt
# Clean-up
rm blacklistComparison.txt resolved.txt
fi
}
printResult() {
command=$@
# If -n flag is set & -e flag is not set
if [[ $numberOfResults -gt 0 && $eFlag -eq 0 ]]; then
command+=" | head -n $numberOfResults"
eval $command
# If -n & -e flag is not set
elif [[ $eFlag -eq 0 ]]; then
eval $command
# If -n flag is not set & -e flag is set
elif [[ $eFlag -eq 1 && $numberOfResults -eq 0 ]]; then
command+=" > blacklistComparison.txt"
eval $command
blacklistCheck
# If -n & -e flag is set
elif [[ $eFlag -eq 1 && $numberOfResults -gt 0 ]]; then
command+=" | head -n $numberOfResults > blacklistComparison.txt"
eval $command
blacklistCheck
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
# Checking whether -e flag is used (iterating through entire params array - i.e. the e parameter does not have to be specified in any specific order)
printf "%s" $@ | grep -q "\-e"
if [ $? -eq 0 ]; then
for index in "${!params[@]}"; do
if [ "${params[$index]}" = "-e" ]; then
eFlag=1
# Cleaning up in the parameter array
unset params[$index]
params=("${params[@]}")
fi
done
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
if [[ $nFlag -eq 1 && $# -lt 4 ]] || [[ $eFlag -eq 1 && $# -lt 3 ]] || [[ $eFlag -eq 1 && $nFlag -eq 1 && $# -lt 5 ]] || [ $# -eq 1 ]; then
echo "ERROR: Incorrect number of parameters used"
echo ${USAGE}
exit 1
fi
# Iterating through flags - applying switch-case based on flag
for param in ${params[@]}
do
case $param in
-c) # Counting connection attempts per IP (sorting in descending order)
cmd="-c"
checkNumOfFuncParams $cmd
var="awk '{print \$1}' $fileName | sort | uniq -c | sort -k1 -n -r | awk '{print \$2 \"\t\" \$1}'"
printResult $var
;;
-r) # Most common result codes (descending order)
cmd="-r"
checkNumOfFuncParams $cmd
var="awk '{print \$1 \"\t\" \$9}' $fileName | sort -k2 -n | uniq -c | sort -k3 -k1 -n -r | awk '{print \$3 \"\t\" \$2}'"
if [[ nFlag -eq 0 ]]; then
printResult $var
else
errorCodesSpecialCase $var
fi
;;
-F) # Most common result codes that indicate failure (descending order)
cmd="-F"
checkNumOfFuncParams $cmd
var="grep '\ [45][0-9][0-9]\ ' $fileName | awk '{print \$9 \"\t\" \$1}' | sort -k2 -n | uniq -c | sort -k2 -k1 -n -r | awk '{print \$2 \"\t\" \$3}'"
if [[ nFlag -eq 0 ]]; then
printResult $var
else
errorCodesSpecialCase $var
fi
;;
-2) # IP addresses which makes the most successful connection attempts (descending order)
cmd="-2"
checkNumOfFuncParams $cmd
var="grep '\ 2[0-9][0-9]\ ' $fileName | awk '{print \$1}' | sort | uniq -c | sort -k1 -n -r | awk '{print \$2 \"\t\" \$1}'"
printResult $var
;;
-t) # Counting number of bytes per IP (descending order)
cmd="-t"
checkNumOfFuncParams $cmd
var="awk '{print \$1 \"\t\" \$10}' $fileName | awk '{array[\$1]+=\$2} END { for (i in array) {print i \"\t\" array[i]}}' | sort -k2 -r -n"
printResult $var
;;
*) # Unknown parameter
echo "ERROR: Unknown parameter $param used"
echo ${USAGE}
exit 1
;;
esac
done
