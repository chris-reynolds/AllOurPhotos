import { API_URL, recordedFetch } from './api';

export const getAlbumItems = async (where = '1=1') => {
  const targetUrl = `${API_URL}/album_items/?where=${where}`;
  return recordedFetch('get album items', targetUrl);
};

export const getAlbumItem = async (id) => {
  const targetUrl = `${API_URL}/album_items/${id}`;
  return recordedFetch('get album item', targetUrl);
};
