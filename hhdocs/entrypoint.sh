#!/bin/sh

if [ "$#" -eq "0" ]; then
	echo "Only mkdocs and mike commands are available"
	exit 1
fi

if [ "$1" = "mkdocs" ]; then
    shift
    mkdocs "$@"
elif [ "$1" = "mike" ]; then
    shift
    mike "$@"
else
    echo "Only mkdocs and mike commands are available"
	exit 1
fi
