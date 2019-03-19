import gdal
import gdal2tiles
from glob import glob

photos = glob('./HSL_GK25_2500m_converted/*.tiff')

for photo in photos:
    gdal2tiles.generate_tiles(photo, './', s_srs='EPSG:3879')