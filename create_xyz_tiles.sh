#!/usr/bin/bash

# Create .png XYZ-map tiles with gdal2tiles.py fork from georeferenced GeoTIFFs. 
# Get forked gdal2tiles.py from https://github.com/CjS77/gdal2tiles
# Fork adds -x flag, which creates tiles with XYZ naming convention instead
# of TMS. (tiling from top-left (XYZ) vs bottom-left (TMS))

# Run script in root dir of GeoTIFFs with:
# bash create_xyz_tiles.sh <gdal2tiles_path> <output_dir>

if [ "$#" = 0 ]; then
    echo "No arguments given <gdal2tiles_path> <output_dir>"
    exit 1
elif [ "$#" = 1 ]; then
    echo "Missing second argument <output_dir>"
    exit 1
elif [ "$#" = 2 ]; then
	forked_gdal2tiles_path=$1
	output_dir=$2
	echo "Starting conversion with input $forked_gdal2tiles_path and output dir $output_dir"
else
   	echo "Too many args."
	exit 1
fi

echo "gdal2tiles.py path: $forked_gdal2tiles_path"
echo "output path: $forked_gdal2tiles_path"

count=$(ls -lR *.tif | wc)
idx=0
for f in *.tif
do
    idx=$((idx + 1))
    echo "Creating tiles from file: "$f
    echo $idx"/"$count
    python "$forked_gdal2tiles_path" -x -e $f "$output_dir"
done
echo "Done"

