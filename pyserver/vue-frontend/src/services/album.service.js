const API_URL = 'http://localhost:8000'; // Assuming your FastAPI server is running on this address

const getHeaders = () => {
  const jam = localStorage.getItem('jam');
  return {
    'Content-Type': 'application/json',
    'Preserve': jam ? jam : ''
  };
};

export const getAlbums = async (orderby = 'id') => {
  const response = await fetch(`${API_URL}/albums/?where=1=1&orderby=${orderby}`, { headers: getHeaders() });
  if (!response.ok) {
    throw new Error('Failed to fetch albums');
  }
  return response.json();
};

export const getAlbum = async (id) => {
  const response = await fetch(`${API_URL}/albums/${id}`, { headers: getHeaders() });
  if (!response.ok) {
    throw new Error(`Failed to fetch album with id ${id}`);
  }
  return response.json();
};

export const createAlbum = async (album) => {
  const response = await fetch(`${API_URL}/albums`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify(album),
  });
  if (!response.ok) {
    throw new Error('Failed to create album');
  }
  return response.json();
};

export const updateAlbum = async (album) => {
  const response = await fetch(`${API_URL}/albums`, {
    method: 'PUT',
    headers: getHeaders(),
    body: JSON.stringify(album),
  });
  if (!response.ok) {
    throw new Error(`Failed to update album with id ${album.id}`);
  }
  return response.json();
};

export const deleteAlbum = async (id) => {
  const response = await fetch(`${API_URL}/albums/${id}`, {
    method: 'DELETE',
    headers: getHeaders(),
  });
  if (!response.ok) {
    throw new Error(`Failed to delete album with id ${id}`);
  }
};
