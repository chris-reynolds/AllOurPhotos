import { API_URL, recordedFetch } from './api';

export const getAlbums = async (orderby = 'id') => {
  const targetUrl = `${API_URL}/albums/?where=1=1&orderby=${orderby}`;
  return recordedFetch('get albums', targetUrl);
};

export const getAlbum = async (id) => {
  const targetUrl = `${API_URL}/albums/${id}`;
  return recordedFetch('get album', targetUrl);
};

export const createAlbum = async (album) => {
  const targetUrl = `${API_URL}/albums`;
  return recordedFetch('create album', targetUrl, {
    method: 'POST',
    body: JSON.stringify(album),
  });
};

export const updateAlbum = async (album) => {
  const targetUrl = `${API_URL}/albums`;
  return recordedFetch('update album', targetUrl, {
    method: 'PUT',
    body: JSON.stringify(album),
  });
};

export const deleteAlbum = async (id) => {
  const targetUrl = `${API_URL}/albums/${id}`;
  return recordedFetch('delete album', targetUrl, {
    method: 'DELETE',
  });
};

