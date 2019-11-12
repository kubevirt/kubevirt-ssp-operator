#!/bin/bash
if [ -z "${V}" ]; then
	V=0
fi

# checking prereqs
if [ -z "${OC}" ]; then
	echo "please define the environment variable 'OC'"
	echo "'OC' should contain the path of the 'oc' binary you want to use to talk with the testing cluster."
	echo "If unsure, use 'OC=/usr/bin/oc'."
	exit 2
fi

MISSING=0
for EXE in jq; do
	if [ ! which -- ${EXE} &> /dev/null ]; then
		echo "missing executable: ${EXE}"
		MISSING=1
	fi
done
[ "${MISSING}" != "0" ] && exit 4

# we can run the real tests now
declare -a PASSED=()
declare -a SKIPPED=()
declare -a FAILED=()
RET=0

for testscript in $( ls *-test-*.sh); do
	OUTPUT=$( mktemp ssp-op-functest-XXXXXXXX )

	testname=$(basename -- "$testscript")
	testname="${testname%.*}"  # see http://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html

	result="???"
	if [ "${V}" == "0" ]; then
		./$testscript &> /dev/null
	else
		printf "* TESTCASE [%-64s] START\n" $testscript
		./$testscript &> ${OUTPUT}
	fi
	RC="$?"
	if [ "$RC" == "0" ]; then
		result="OK"
		PASSED[${#PASSED[@]}]="$testscript"
	else
		if [ "$RC" == "99" ] ; then
			result="SKIP"
			SKIPPED[${#SKIPPED[@]}]="$testscript"
		else
			result="FAILED"
			FAILED[${#FAILED[@]}]="$testscript"
			RET=1
		fi
	fi
	if [ "${V}" == "0" ]; then
		printf "* [%-64s] %s\n" $testscript $result
	else
		if [ "${RET}" != "0" ]; then
			cat ${OUTPUT}
		fi
		printf "  TESTCASE [%-64s] %s\n" $testscript $result
	fi

	rm -f ${OUTPUT}
done

printf "=============\n"
printf "FAILED  : %s %s\n" "${#FAILED[@]}" "${FAILED[*]}"
printf "SKIPPED : %s %s\n" "${#SKIPPED[@]}" "${SKIPPED[*]}"
printf "PASSED  : %s %s\n" "${#PASSED[@]}" "${PASSED[*]}"
exit $RET
