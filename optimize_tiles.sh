#!/usr/bin/bash

# Usage: optimize_tiles.sh <input_dir> <output_dir>
#
# Read in recursively an input directory of .PNG map tiles, remove 'blank' tiles (tiles less thank 2K in size) and convert
# tile to web-optimized .JPG tiles with ImageMagick. Save optimized tile to to output directory, preservering relative 
# directory tree of input directory.

if [ "$#" = 0 ]; then
    echo "No arguments given <input_dir> <output_dir>"
    exit 1
elif [ "$#" = 1 ]; then
    echo "Missing second argument <output_dir>"
    exit 1
elif [ "$#" = 2 ]; then
	input_dir=$1
	output_dir=$2
	echo "Starting conversion with input $input_dir and output dir $output_dir"
else
   	echo "Too many args."
	exit 1
fi

files=$(find $input_dir -name "*.png")

find "$input_dir" -type d -print0 | xargs -0 -I {} mkdir -p $output_dir"/{}"

for f in $files
do
    echo "$f"
    convert -strip -sampling-factor 4:2:0 -define jpeg:dct-method=float -interlace Plane -quality 75% "$f" "$output_dir/${f/%.png/.jpg}"
done
echo "Done."
exit 0