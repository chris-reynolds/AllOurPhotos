import sharp from 'sharp';
import piexif from 'piexifjs';
import fs from 'fs';
import path from 'path';

export async function makeThumbnail(imagePath, targetPath, exifData) {
  try {
    let image = sharp(imagePath);
    const metadata = await image.metadata();

    const scale = Math.max(metadata.height, metadata.width) / 640;
    const newWidth = Math.floor(metadata.width / scale);
    const newHeight = Math.floor(metadata.height / scale);

    image = image.resize(newWidth, newHeight, {
      fit: 'inside',
      kernel: sharp.kernel.lanczos3
    });

    // Handle EXIF orientation
    if (exifData && exifData['0th'] && exifData['0th'][274]) {
      const orientation = exifData['0th'][274];
      if (orientation === 6) {
        image = image.rotate(270);
      } else if (orientation === 3) {
        image = image.rotate(180);
      } else if (orientation === 8) {
        image = image.rotate(90);
      }
    }

    await image.jpeg({ quality: 50 }).toFile(targetPath);
    return true;
  } catch (error) {
    console.error('Error in makeThumbnail:', error);
    throw error;
  }
}

export function filterMetadata(exifData) {
  if (!exifData) return {};

  const result = {};
  const excludeKeys = [50341, 37500, 37510];

  for (const [key, value] of Object.entries(exifData)) {
    const keyNum = parseInt(key);
    if (!excludeKeys.includes(keyNum) && keyNum < 59000) {
      if (typeof value === 'string' && value.length < 100) {
        result[key] = value.replace(/\x00/g, '').trim();
      } else if (typeof value !== 'string') {
        result[key] = value;
      }
    }
  }

  return result;
}

export function forceDir(pathname) {
  if (!fs.existsSync(pathname)) {
    fs.mkdirSync(pathname, { recursive: true });
  }
}

export async function cropImage(sourcePath, targetPath, left, top, right, bottom, exifData) {
  try {
    const image = sharp(sourcePath);
    const metadata = await image.metadata();

    const width = right - left;
    const height = bottom - top;

    await image
      .extract({ left, top, width, height })
      .jpeg({ quality: 100, progressive: true })
      .toFile(targetPath);

    return { width, height };
  } catch (error) {
    console.error('Error cropping image:', error);
    throw error;
  }
}

export async function rotateImage(imagePath, angle) {
  try {
    let subangle = angle % 90;
    if (subangle > 45) {
      subangle = 90 - subangle;
    }

    const image = sharp(imagePath);
    const metadata = await image.metadata();

    const borderProportion = Math.min(0.1, Math.abs(Math.tan(subangle * Math.PI / 180) / 2));
    const topBorder = Math.floor(metadata.width * borderProportion);
    const sideBorder = Math.floor(metadata.height * borderProportion);

    const rotated = await image
      .rotate(angle, { background: { r: 0, g: 0, b: 0, alpha: 0 } })
      .extract({
        left: sideBorder,
        top: topBorder,
        width: metadata.width - 2 * sideBorder,
        height: metadata.height - 2 * topBorder
      })
      .jpeg({ quality: 100 })
      .toBuffer();

    return rotated;
  } catch (error) {
    console.error('Error rotating image:', error);
    throw error;
  }
}
