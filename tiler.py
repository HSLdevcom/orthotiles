import gdal
import gdal2tiles
from glob import glob

hsy_photos = glob('./HSL_GK25_2500m_converted/*.tif')
mml_photos = glob('./mml_orthophotos/*.tif')

for photo in hsy_photos:
    gdal2tiles.generate_tiles(photo, './tiles', s_srs='EPSG:3879')

for photo in mml_photos:    
    gdal2tiles.generate_tiles(photo, './tiles/', s_srs='EPSG:3067', options={'resume':True})
