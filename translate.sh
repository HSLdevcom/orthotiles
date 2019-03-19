#!/bin/bash

for %%F in {*.tif} 
do
  gdal_translate -a_srs EPSG:3879 -co "TILED=YES" -co "BLOCKXSIZE=512" -co "BLOCKYSIZE=512" -co "COMPRESS=JPEG" -co JPEG_QUALITY=100 %%F ./HSL_GK25_2500m_converted/%%~nF.tiff
  echo Adding overviews on file %%~nF.tiff
done

conda activate gdalenv

python tiler.py

#  gdaladdo -r average --config COMPRESS_OVERVIEW JPEG --config INTERLEAVE_OVERVIEW PIXEL --config JPEG_QUALITY_OVERVIEW 100 ./HSL_GK25_2500m_converted/%%~nF.tiff 2 4 8 16 32 64
