# Instructions for new orthophotos

This is a step-by-step guide to convert new orthophotos from HSY to tiled XYZ map API. New orthophoto is expected to be in [ECW format](https://gdal.org/drivers/raster/ecw.html), and not covering all the interest area. MML imagery is used where there's no coverage of the HSY imagery. The result is a set of indexed jpeg-images sized 256x256 pixels, and they will be published on Azure.

Process steps in a nutshell:
- Convert HSY imagery from ECW to GeoTIFF
- Download MML imagery
- Transform MML imagery to ETRS-GK25 (the same as HSY)
- Combine HSY and MML imageries together
- Transform new image to Web Mercator
- Create XYZ tiles from imagery
- Convert final files from png to jpg

Note! The steps include many JPEG-conversion. Remember that JPEG is lossy compression algorithm, and therefore the image quality drops on every compression! If that becomes a problem consider the following choices:
- complete the processing with fewer steps, e.g. using Python script with gdal or rasterio library combining the steps without writing the data between the steps (could be hard due to the size of the data)
- use `-co JPEG_QUALITY=100` -GDAL parameter (it is *the least* lossy way to use jpeg)
- use loseless compression, e.g., LZW (remember, the dataset is huge)

## 1. Prepare the environment

*Use the previously utilized VM if possible to skip this step.*

Prepare a virtual machine and a data disk. There are not known limitations of the specs of the selected VM, but enough powerful machine is highly recommended to finish the process in a reasonable time. Azure's Standard D4s v3 (4 vCPUS, 16 GiB RAM) is tested to be okay. The data disk should be sized at least 1 TB, but 2 TB is safer choice. Debian 11 has been used lately, but the commands should work on other Linux distrubutions as well. Mount data disk (refer the instructions of the platform provider). On the example commands `/data` mount point has been used, that doesn't matter if you use different naming. Just remember use the correct path on commands.

Install the following tools:
- gdal: `sudo apt install gdal-bin` *(Make sure the version is 3.1 or newer! Otherwise gdal2tiles won't work for xyz-tiling.)*
- imagemagick: `sudo apt install imagemagick`
- python3: Probably preinstalled.
- AzCopy: See the instructions [here](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10)

## 2. Prepare the local environment

If HSY imagery comes in ECW format, it cannot be converted on GDAL installed on the server, unless the GDAL has been build from source with ECW support. Therefore it's easier to first convert ECW to GeoTiff on your local machine using GDAL binaries built for QGIS. *(Note! Not sure if Linux builds of QGIS have ECW support! Instructions are for Windows and OSGeo4W Shell.)* Install [QGIS](https://qgis.org/en/site/) which comes with OSGeo4W Shell where GDAL can be used.


## 3. Convert HSY imagery (local)

You probably got images on an external hard disk drive. Get the proper image file and convert it with GDAL to JPEG-compressed GeoTIFF:
```cmd
gdal_translate --config GDAL_CACHEMAX 16000 -co NUM_THREADS=ALL_CPUS -co COMPRESS=JPEG -co PHOTOMETRIC=YCBCR -co TILED=YES -co BIGTIFF=YES -a_nodata 0 HSY_GK25.jp2 hsy-gk25.tif
```
The first two parameters are just configurations for the runtime to make the processing a bit faster. Adjust them if needed. `--config GDAL_CACHEMAX 16000 -co NUM_THREADS=ALL_CPUS` means GDAL can use 16 GiB RAM and all cpus for a compression process.

**Note! Pick up carefully the right data from HDD. Imagery to be deployed should have restriction areas blurred!**

Upload the converted image to the server via Azure Storage (also handy if you want to preview it) or straight to the machine. The commands expected the image to be downloaded to `/data/hsy-gk25.tif`

## 4. Download imagery from MML

Download images with [Digitransit tools](https://github.com/HSLdevcom/digitransit-tools/tree/master/dem-tools)

Clone the repository, install tools (probably everything should be already installed at this point), set up MML key and run:
```bash
python3 nls-dem-downloader.py config.json HSL /data/2021/mml_orthophotos/raw -orto -v
```


## 5. Convert MML imagery

First, MML images should be converted to RGB GeoTIFFs (originally, some of them could be grayscaled!). This is a bit hacky way to recognize grayscaled image with `gdalinfo`, but should work:
```bash
cd /data/mml_orthophotos/

for i in raw/*.jp2
do
  echo $i
  if [ "$(gdalinfo $i | grep Gray)" ]
    then
      gdal_translate -b 1 -b 1 -b 1 -colorinterp red,green,blue $i unified/$(basename $i)
    else
      cp $i unified/$(basename $i)
  fi;
done;
```

After that, create a virtual raster mosaic and transform it to ETRS-GK25 coordinate reference system. (The same as HSY imagery is delivered.)
```bash
gdalbuildvrt mml-tm35fin.vrt unified/*.jp2

gdalwarp -t_srs EPSG:3879 -r bilinear -co COMPRESS=JPEG -co PHOTOMETRIC=YCBCR -co TILED=YES -co BIGTIFF=YES -srcnodata "0 0 0" -dstnodata "0 0 0" mml-tm35fin.vrt mml-gk25.tif
```

Remember, `--config GDAL_CACHEMAX <ram>  -co NUM_THREADS=<cpu count>` can be used!


## 6. Combine HSY and MML imageries

You might have noticed `nodata` -parameters on previous commands. The purpose of them is to keep black pixels as no data for a couple of reasons: to make sure MML imagery will show up where HSY images are not available and to prevent black XYZ tiles to be rendered (speeds up the process).

Now, let's make sure nodata is still assigned for HSY and after that combine the imageries:
```bash
cd /data/

gdal_edit.py -a_nodata 0 hsy-gk25.tif

gdalbuildvrt -resolution highest -allow_projection_difference image-gk25.vrt mml_orthophotos/mml-gk25.tif hsy-gk25.tif
```

## 7. Transform the image to Web Mercator

Use `gdalwarp` to transform image to EPSG:3857 (the final projection). Although `gdal2tiles.py` could handle the transformation as well, the process is significantly faster this way. Note `GDAL_CACHEMAX` and `NUM_THREADS`. `JPEG_QUALITY` has been set up to `100` at this point so that quality does not drop too much on this step.

```bash
cd /data/

gdalwarp --config GDAL_CACHEMAX 4000 -co NUM_THREADS=ALL_CPUS -co COMPRESS=JPEG -co PHOTOMETRIC=YCBCR -co JPEG_QUALITY=100 -co TILED=YES -co BIGTIFF=YES -t_srs EPSG:3857 -r bilinear -srcnodata 0 0 0 image-gk25.vrt image-final.tif
```

*Optional: Upload the final image to Azure Storage or locally and inspect that everything looks fine at this point. It could be annoying to find some errors after two weeks of `gdal2tiles.py`-process.

## 8. Create XYZ tiling

The most time consuming part starts. At this stage at the latest, start [`screen`](https://linuxize.com/post/how-to-use-linux-screen/) to make sure the processing would not stop if use exit the shell! The processing could take 1 week or more, and your network would probably not be stable so long to VM to run the command directly on your SSH session :)

```
cd /data/
gdal2tiles.py --config GDAL_CACHEMAX 4000 -e -x --xyz --processes=4 --zoom=8-19 image-final.tif output/
```

The command creates folders 8-19 under `output/` -directory, where all images will be placed as correctly indexed. If some errors happen and the process will be aborted, `-e` (resume mode) helps to skip already created images.

## 9. JPG conversion

Use the helper script [`optimize_tiles.sh`](./optimize_tiles.sh) to convert png files to JPEG format. Clone the script somewhere and call it like following:
```bash
cd /data/
mkdir final
cd output/

for z in {8...19}
do 
  ~/orthotiles/optimize_tiles.sh $z/ /data/final/
done
```

Actually JPG-conversion can be started by subdirectories also already while `gdal2tiles.py` is still running. (The certain zoom level should be ready, though.)

```bash
cd /data/output/
~/orthotiles/optimize_tiles.sh 19/ /data/final/
```

Note that `optimize_tiles.sh` seems not to check the destination, so if you interrupt the script, it will start again from the beginning.

## 10. Upload to Azure

Last but not least, it's time to upload files to Azure Blob Storage.

A couple of notes:
- it's better to use the existing blob container, because then the clients don't need to reconfigure their apps
- backup the existing content of the blob container to another. Make sure backup is not on `hot` access tier (more expensive and no benefits for backups)
- new images are immediately available after uploaded to Storage, so be careful and remember to backup!

Get Shared Access Signature (SAS) for Blob Container with suitable permissions to add and rewrite files.

Run azcopy for folder by folder or all at once:
```bash
cd /data/final/

for z in {8...19}
do
  azcopy copy --recursive z "https://{myaccount}.blob.core.windows.net/{mycontainer}?{my-sas-token}"
done
```

## All done!

Verify that orthophoto layers work (e.g. on Kuljettajaohje and Reittiloki) and clean up / shut down unneeded resources.
