#!/bin/bash

# ABOUT
# This is a bash script for Linux that will scan the project file for notes
# starting with 'mod_'. These notes will be treated as pieces of shader
# scripts that will be inserted into the relevant shaders that call them.
# This script should generally not be needed by the user, however it is
# here to help share shader code across shaders.
#
# This script is hacked together and likely not safe in complex situations.
# It also does NOT handle nesting of any kind. Make sure to commit your
# changes before running this script.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SHADER_DIR="shaders/"
MOD_DIR="notes/mod_"

function process_file {
	FILE_NAME=$1
	FILE_EXTENSION=$2
	FILE_SUBPATH=$(find "$SHADER_DIR" -name "*$FILE_NAME*.$FILE_EXTENSION")
	FILE_PATH="${SCRIPT_DIR}/${FILE_SUBPATH}"
	echo "Checking file $FILE_PATH..."
	# Make sure the file exists:
	if [ ! -f "$FILE_PATH" ]; then
		return 0
	fi

	echo "Scanning for includes..."
	# Loop through each occurrence of "//#include" and sub-in, if possible
	grep '//#include' $FILE_PATH | grep -oE '\w+$' | while read line; do
		# Make sure the file exists:
		echo "Found: $line"
		line_path=$(echo "$SCRIPT_DIR/${MOD_DIR}${line}/mod_$line.txt")

		if [ ! -f $line_path ]; then
			continue
		fi

		echo "Replacing: $line"
#		file_data="$(cat $line_path)"
		MATCH_START="\/\/#include $line"
		MATCH_END="\/\/#end $line"
		sed -i -e "/$MATCH_START/,/$MATCH_END/{/$MATCH_START/n;/$MATCH_END/!d}" $FILE_PATH
		sed -i -e "/$MATCH_START/r $line_path"  $FILE_PATH
	done
}

# Process fragment shaders:
find "${SCRIPT_DIR}/${SHADER_DIR}" -name "*.fsh" | while read line; do
	name=$(echo "$line" | grep -Eo '/\w+.fsh' | grep -Eo '\w+' | head -n 1)
	process_file $name "fsh"
done


# Process vertex shaders:
find "${SCRIPT_DIR}/${SHADER_DIR}" -name "*.vsh" | while read line; do
	name=$(echo "$line" | grep -Eo '/\w+.vsh' | grep -Eo '\w+' | head -n 1)
	process_file $name "vsh"
done
