#!/usr/bin/env sh

manual=$(curl --silent https://raw.githubusercontent.com/jgm/pandoc/master/MANUAL.txt)

vartime=false

variablesec=$(echo "$manual" | while read line
do
    if [ "$line" = "## Variables" ]
    then
        vartime=true
    fi

    if [ "$line" = "## Typography" ]
    then
        vartime=false
    fi

    if $vartime
    then
    	echo $line
	fi
done)

echo "$variablesec" | pcregrep '\n\n`[^`]+`'

