#!/bin/zsh

# Renders the documentation diagramms using d2
# Place ${assetName}-source.d2 file in the same directory as the expected output
# This script is not part of the build process, or github actions

find . -type f -name "*-source.d2" | while read -r file
do
	base="${file%-source.d2}"
	d2 $file "${base}@2x.png"\
		--layout elk 
	d2 $file "${base}~dark@2x.png"\
		--layout elk\
		--theme 200
done