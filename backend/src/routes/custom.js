import express from 'express';
import multer from 'multer';
import sharp from 'sharp';
import ffmpeg from 'fluent-ffmpeg';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { readFileSync } from 'fs';
import sequelize from '../config/database.js';
import Snap from '../models/Snap.js';
import Session from '../models/Session.js';
import User from '../models/User.js';
import { getUserFromSession } from '../middleware/auth.js';
import { getLocation, dmsToDeg, trimLocation } from '../utils/geo.js';
import { makeThumbnail, filterMetadata, forceDir, cropImage, rotateImage } from '../utils/imageProcessing.js';

const config = JSON.parse(readFileSync(new URL('../../config.json', import.meta.url)));

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

const ROOT_DIR = process.env.PHOTOS_DIR;

// Get version
router.get('/version', (req, res) => {
  const filename = path.basename(__filename);
  const stats = fs.statSync(__filename);
  const modifiedDate = stats.mtime;
  res.send(`AllOurPhotos ${filename} @ ${modifiedDate}`);
});

// Create session (login)
router.get('/ses/:user/:password/:source', async (req, res) => {
  try {
    const { user, password, source } = req.params;
    const cleanSource = source.replace(/'/g, "''");

    const [results] = await sequelize.query(
      `SELECT spsessioncreate('${user}','${password}','${cleanSource}') as sessionid`
    );
    const sessionid = results[0].sessionid;

    const responseData = { jam: `${sessionid}` };

    if (sessionid < 0) {
      res.clearCookie('Preserve');
    } else {
      res.cookie('jam', `${sessionid}`);
    }

    res.json(responseData);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Custom SQL queries
router.get('/find/:key', async (req, res) => {
  try {
    const { key } = req.params;
    const queryList = config.find;

    if (!queryList || !queryList[key]) {
      return res.status(404).json({ detail: 'not found in line' });
    }

    let sql = queryList[key];
    const queryParams = req.query;

    for (const [paramKey, paramValue] of Object.entries(queryParams)) {
      sql = sql.replace(`@${paramKey}`, paramValue);
    }

    const [results] = await sequelize.query(sql);
    res.json(results);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Crop image
router.get('/crop/:id/:left/:top/:right/:bottom', async (req, res) => {
  let progress = 'start';
  try {
    const { id, left, top, right, bottom } = req.params;

    progress = 'check security';
    const preserve = req.cookies.Preserve || req.headers.preserve;
    if (!preserve) {
      return res.status(401).json({ detail: 'Unauthorized' });
    }

    const preserveData = JSON.parse(preserve);
    const session = await Session.findByPk(parseInt(preserveData.jam));
    const currentUser = await getUserFromSession(session);

    progress = 'get original snap';
    const originalSnap = await Snap.findByPk(id);
    if (!originalSnap) {
      return res.status(404).json({ detail: 'Snap not found' });
    }

    progress = 'check prior crops';
    const newSource = `Crop+${id}`;
    const priorCrops = await Snap.findAll({
      where: sequelize.literal(`import_source='${newSource}'`)
    });

    progress = 'compute filenames';
    const sourceFullPath = path.join(ROOT_DIR, originalSnap.directory, originalSnap.file_name);
    const extPos = sourceFullPath.lastIndexOf('.');
    const targetFullPath = `${sourceFullPath.substring(0, extPos)}_cp${priorCrops.length + 1}${sourceFullPath.substring(extPos)}`;
    const targetFilename = path.basename(targetFullPath);

    if (!fs.existsSync(sourceFullPath)) {
      return res.status(404).json({ detail: `${sourceFullPath} not found in cropPic` });
    }

    progress = 'crop image';
    const { width, height } = await cropImage(
      sourceFullPath,
      targetFullPath,
      parseInt(left),
      parseInt(top),
      parseInt(right),
      parseInt(bottom)
    );

    progress = 'setup database snap';
    const newSnap = {
      ...originalSnap.toJSON(),
      file_name: targetFilename,
      import_source: newSource,
      width,
      height,
      media_length: fs.statSync(targetFullPath).size,
      session_id: session.id,
      user_id: currentUser.id,
      id: undefined
    };

    progress = 'save db snap';
    const savedSnap = await Snap.create(newSnap);

    const monthDir = newSnap.directory;
    const targetThumbnail = path.join(ROOT_DIR, monthDir, 'thumbnails', targetFilename);
    const targetMetadata = path.join(ROOT_DIR, monthDir, 'metadata', `${targetFilename}.json`);

    progress = 'make thumbnail';
    await makeThumbnail(targetFullPath, targetThumbnail, null);

    progress = 'writing the metadata';
    const metadata = {};
    fs.writeFileSync(targetMetadata, JSON.stringify(metadata, null, 4));

    res.json(savedSnap);
  } catch (error) {
    console.error(`Error in cropPic at ${progress}:`, error);
    res.status(500).json({ detail: `cropPic()-${progress}-${error.message}` });
  }
});

// Rotate image
router.get('/rotate/:angle/:aPath(*)', async (req, res) => {
  try {
    const { angle, aPath } = req.params;
    const angleNum = parseInt(angle);

    const targetFilename = path.join(ROOT_DIR, aPath);
    if (!fs.existsSync(targetFilename)) {
      return res.status(404).json({ detail: `${aPath} not found` });
    }

    if (angleNum === 0) {
      return res.sendFile(targetFilename);
    }

    const rotatedBuffer = await rotateImage(targetFilename, angleNum);

    const rnd = Math.floor(Math.random() * 1000);
    const tempPath = path.join('temp', `fred${rnd}.jpg`);
    forceDir('temp');
    fs.writeFileSync(tempPath, rotatedBuffer);

    res.sendFile(path.resolve(tempPath));
  } catch (error) {
    console.error('Error in rotatePic:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Upload image
router.post('/upload2/:modified/:filename/:sourceDevice', upload.single('myfile'), async (req, res) => {
  let progress = 'start';
  try {
    const { modified, filename, sourceDevice } = req.params;
    const fileBuffer = req.file.buffer;

    progress = 'reading image';
    const mediaLength = fileBuffer.length;

    progress = 'decoding image';
    const image = sharp(fileBuffer);
    const metadata = await image.metadata();
    const fullWidth = metadata.width;
    const fullHeight = metadata.height;

    progress = 'processing exif';
    const exifData = metadata.exif ? metadata.exif : {};

    const taken = exifData.DateTime || modified;
    const dateOriginal = exifData.DateTimeOriginal || taken;

    progress = 'processing dates';
    const takenDate = new Date(dateOriginal.replace(/(\d{4}):(\d{2}):(\d{2})/, '$1-$2-$3'));
    const monthDir = takenDate.toISOString().substring(0, 7);

    const targetFile = path.join(ROOT_DIR, monthDir, filename);
    const targetThumbnail = path.join(ROOT_DIR, monthDir, 'thumbnails', filename);
    const targetMetadata = path.join(ROOT_DIR, monthDir, 'metadata', `${filename}.json`);

    progress = 'creating directories';
    forceDir(path.join(ROOT_DIR, monthDir));
    forceDir(path.join(ROOT_DIR, monthDir, 'thumbnails'));
    forceDir(path.join(ROOT_DIR, monthDir, 'metadata'));

    progress = 'writing image file';
    fs.writeFileSync(targetFile, fileBuffer);

    progress = 'make thumbnail';
    await makeThumbnail(targetFile, targetThumbnail, exifData);

    progress = 'writing metadata';
    const filteredMetadata = filterMetadata(exifData);
    fs.writeFileSync(targetMetadata, JSON.stringify(filteredMetadata, null, 4));

    progress = 'creating snap record';
    const newSnap = await makeSnapDatabaseRow(
      fullWidth,
      fullHeight,
      filteredMetadata,
      sourceDevice,
      monthDir,
      filename,
      takenDate,
      modified,
      mediaLength
    );

    progress = 'checking for duplicates';
    const preserve = req.cookies.Preserve || req.headers.preserve;
    const preserveData = JSON.parse(preserve);
    const session = await Session.findByPk(parseInt(preserveData.jam));

    const existingSnaps = await Snap.findAll({
      where: sequelize.literal(`file_name='${filename}' AND directory='${monthDir}'`)
    });

    if (existingSnaps.length > 0) {
      return res.status(409).json({ detail: `Duplicate entry for file '${filename}' in directory '${monthDir}'` });
    }

    newSnap.session_id = session.id;
    newSnap.user_id = session.user_id;

    const createdSnap = await Snap.create(newSnap);
    console.log(`uploaded ${filename}`);

    res.json(createdSnap);
  } catch (error) {
    console.error(`Error in uploader at ${progress}:`, error);
    res.status(500).json({ detail: `During ${progress}: ${error.message}` });
  }
});

// Serve photos
router.get('/photos/:aPath(*)', (req, res) => {
  const { aPath } = req.params;
  const fullFileName = path.join(ROOT_DIR, aPath);

  const cacheHeaders = {};
  if (aPath.toLowerCase().endsWith('txt')) {
    cacheHeaders['Cache-Control'] = 'no-cache, no-store, must-revalidate';
    cacheHeaders['Pragma'] = 'no-cache';
    cacheHeaders['Expires'] = '0';
  }

  if (fs.existsSync(fullFileName)) {
    res.set(cacheHeaders);
    res.sendFile(fullFileName);
  } else {
    res.status(404).json({ detail: `'${aPath}' is not found.` });
  }
});

// Update photo file
router.put('/photos/:aPath(*)', async (req, res) => {
  const { aPath } = req.params;
  const fullFileName = path.join(ROOT_DIR, aPath);

  console.log('photos_put', fullFileName);

  if (fs.existsSync(fullFileName)) {
    const contents = await req.body;
    fs.writeFileSync(fullFileName, contents);
    res.json({ success: true });
  } else {
    res.status(404).json({ detail: `'${aPath}' is not found.` });
  }
});

async function makeSnapDatabaseRow(width, height, filteredExif, sourceDevice, monthDir, filename, takenDate, modified, mediaLength) {
  try {
    const model = filteredExif.Model || null;
    const make = filteredExif.Make || null;
    const deviceName = model || make || sourceDevice || 'No Device';
    const importSource = sourceDevice || model || 'No source';

    const newSnap = {
      file_name: filename,
      directory: monthDir,
      width,
      height,
      taken_date: takenDate,
      modified_date: new Date(modified.replace(/(\d{4}):(\d{2}):(\d{2})/, '$1-$2-$3')),
      device_name: deviceName,
      rotation: '0',
      degrees: 0,
      import_source: importSource,
      imported_date: new Date(),
      original_taken_date: takenDate,
      media_length: mediaLength,
      caption: '',
      tag_list: ''
    };

    const software = filteredExif['device.software'] || '';
    if (software.toLowerCase().includes('scan')) {
      newSnap.import_source = (newSnap.import_source || '') + ' scanned';
    }

    try {
      const gpsInfo = filteredExif.GPSInfo;
      if (gpsInfo && Object.keys(gpsInfo).length > 1) {
        const { latitude, longitude } = dmsToDeg(gpsInfo);
        newSnap.latitude = latitude;
        newSnap.longitude = longitude;

        if (latitude && Math.abs(latitude) > 1e-6) {
          const location = await getLocation(longitude, latitude);
          if (location) {
            newSnap.location = trimLocation(location);
          }
          console.log(`found location: ${newSnap.location}`);
        }
      }
    } catch (error) {
      console.log('gps ignored');
    }

    newSnap.metadata = JSON.stringify(filteredExif, null, 4);
    const extIndex = filename.lastIndexOf('.');
    newSnap.media_type = filename.substring(extIndex + 1).toLowerCase();

    return newSnap;
  } catch (error) {
    console.error('Error in makeSnapDatabaseRow:', error);
    throw error;
  }
}

export default router;
