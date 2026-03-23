import { API_URL, recordedFetch } from './api';

export const getSnaps = async () => {
  const targetUrl = `${API_URL}/snaps/`;
  return recordedFetch('get snaps', targetUrl);
};

export const getAlbumSnaps = async (album_id) => {
  const targetUrl = `${API_URL}/snaps/?where=id in (select snap_id from aopalbum_items where album_id=${album_id})&orderby=taken_date`;
  return recordedFetch('get album snaps', targetUrl);
};

export const filterSnaps = async (filter) => {
  const conditions = [];
  if (filter.startdate) {
    conditions.push(`taken_date >= '${filter.startdate.toISOString()}'`);
  }
  if (filter.enddate) {
    conditions.push(`taken_date < '${filter.enddate.toISOString()}'`);
  }
  if (filter.description) {
    conditions.push(`description like '%${filter.description}%'`);
  }
  if (filter.ranking) {
    conditions.push(`ranking in (${filter.ranking})`);
  }
  if (filter.albumid) {
    conditions.push(`id in (select snap_id from aopalbum_items where album_id=${filter.albumid})`);
  }

  let query = '';
  if (conditions.length > 0) {
    query = `?where=${conditions.join(' and ')}`;
  }

  if (filter.orderby) {
    query += `${query ? '&' : '?'}orderby=${filter.orderby}`;
  }

  const targetUrl = `${API_URL}/snaps/${query}`;
  return recordedFetch('filter snaps', targetUrl);
};


export const getSnap = async (id) => {
  const targetUrl = `${API_URL}/snaps/${id}`;
  return recordedFetch('get snap', targetUrl);
};

export const createSnap = async (snap) => {
  const targetUrl = `${API_URL}/snaps`;
  return recordedFetch('create snap', targetUrl, {
    method: 'POST',
    body: JSON.stringify(snap),
  });
};

export const updateSnap = async (snap) => {
  const targetUrl = `${API_URL}/snaps`;
  return recordedFetch('update snap', targetUrl, {
    method: 'PUT',
    body: JSON.stringify(snap),
  });
};

export const deleteSnap = async (id) => {
  const targetUrl = `${API_URL}/snaps/${id}`;
  return recordedFetch('delete snap', targetUrl, {
    method: 'DELETE',
  });
};

export const getThumbnailUrl = (snap) => {
  return `${API_URL}/photos/${snap.directory}/thumbnails/${snap.file_name}`;
};

export const getFullUrl = (snap) => {
  return `${API_URL}/photos/${snap.directory}/${snap.file_name}`;
};
