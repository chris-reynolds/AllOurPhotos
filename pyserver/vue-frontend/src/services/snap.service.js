import { API_URL, recordedFetch } from './api';

export const getSnaps = async () => {
  const targetUrl = `${API_URL}/snaps/`;
  return recordedFetch('get snaps', targetUrl);
};

export const getAlbumSnaps = async (album_id) => {
  const targetUrl = `${API_URL}/snaps/?where=id in (select snap_id from aopalbum_items where album_id=${album_id})&orderby=taken_date`;
  return recordedFetch('get album snaps', targetUrl);
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
