
### Downloading data from HSL area

##### download hsl/hsy orthophotos (from external hard drive)

##### download mml orthophotos

set up [digtransit-dem-tools](https://github.com/HSLdevcom/digitransit-dem-tools/) virtualenv and config file 

run  `python nls-dem-downloader.py config.json HSL ./data -orto -v`

### Set up tiling environment

##### download miniconda3 https://docs.conda.io/en/latest/miniconda.html

##### create environment `conda env create -f orthoenv.yaml`

### Create and optimize tiles

Get gdal2tiles.py -fork supporting XYZ-tiling scheme. https://github.com/CjS77/gdal2tiles

Create tiles (can take many days)

`bash create_xyz_tiles.sh <forked_gdal2tiles.py_path <output_dir>`

Get ImageMagick for optimizing and JPEG compression of tiles and run tiling script

`sudo apt-get install imagemagick`

Optimize tiles

`bash optimize_tiles.sh <input_dir> <output_dir>`

### Upload tiles to Blob Storage

Get azcopy https://aka.ms/downloadazcopy-v10-linux
https://github.com/Azure/azure-storage-azcopy

`./azcopy cp /data/directory1 "https://myaccount.blob.core.windows.net/mycontainer/directory1?sastokenhere" --recursive=true`