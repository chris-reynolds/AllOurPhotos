import axios from 'axios';

const geoCache = {};

export function dmsToDeg(gpsInfo) {
  const latSign = gpsInfo[1] === 'N' ? 1 : -1;
  const latValues = gpsInfo[2];
  const lngSign = gpsInfo[3] === 'E' ? 1 : -1;
  const lngValues = gpsInfo[4];

  const latVal = latValues[0] + latValues[1] / 60 + latValues[2] / 3600;
  const lngVal = lngValues[0] + lngValues[1] / 60 + lngValues[2] / 3600;

  return { latitude: latVal * latSign, longitude: lngVal * lngSign };
}

function calcKey(longitude, latitude) {
  const tileSizeKms = 5.0;
  const latDegree = 111.0;
  const longDegree = 111.0 * Math.cos(latitude * Math.PI / 180);
  const latTiles = Math.floor(latitude * latDegree / tileSizeKms);
  const longTiles = Math.floor(longitude * longDegree / tileSizeKms);
  console.log(`Geo-key ${longTiles}:${latTiles} for (${longitude},${latitude})`);
  return `${longTiles}:${latTiles}`;
}

function removeDiacritics(str) {
  const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽžĀāĒēĪīŌōŪūþ';
  const withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZzAaEeIiOoUup';

  let result = str;
  for (let i = 0; i < withDia.length; i++) {
    result = result.replace(new RegExp(withDia[i], 'g'), withoutDia[i]);
  }
  return result;
}

async function urlLookupFromCoordinates(latitude, longitude) {
  const host = 'https://nominatim.openstreetmap.org/reverse?format=jsonv2&zoom=14';
  const url = `${host}&lat=${latitude}&lon=${longitude}`;

  console.log(`Sending ${url}...`);
  const response = await axios.get(url);

  if (response.status !== 200) {
    throw new Error(`openstreetmap lookup failed: ${response.data}`);
  }

  const data = response.data;
  const result = data.display_name;

  if (result) {
    return removeDiacritics(result);
  } else {
    throw new Error('Bad openstreetmap response format');
  }
}

export async function getLocation(longitude, latitude) {
  const key = calcKey(longitude, latitude);

  if (!geoCache[key]) {
    const newLocation = await urlLookupFromCoordinates(latitude, longitude);
    geoCache[key] = newLocation;
  }

  return geoCache[key];
}

export function trimLocation(location) {
  return location;
}
