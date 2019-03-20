
### Downloading data from HSL area

##### download hsl/hsy orthophotos (from external hard drive)

##### download mml orthophotos

set up [digtransit-dem-tools](https://github.com/HSLdevcom/digitransit-dem-tools/) virtualenv and config file 

run  `python nls-dem-downloader.py config.json HSL ./data -orto -v`

### Set up tiling environment

##### download miniconda3 https://docs.conda.io/en/latest/miniconda.html

##### create environment `conda env create -f orthoenv.yaml`

### Run transform and tiling

`bash translate.sh`
