import argparse
import rasterio
from tqdm import tqdm


PIXEL_SIZE = 0.05
ROTATION = 0


def fix_transformation(file_name: str):
    dataset = rasterio.open(file_name, 'r+')

    transform = dataset.read_transform()

    transform[1] = PIXEL_SIZE
    transform[2] = ROTATION

    transform[4] = ROTATION
    transform[5] = -PIXEL_SIZE

    dataset.write_transform(transform)
    dataset.close()



if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('filenames', nargs='+')

    args = parser.parse_args()

    print(f"Processing {len(args.filenames)} files...")
    for f in tqdm(args.filenames):
        fix_transformation(f)
    print("Done.")
