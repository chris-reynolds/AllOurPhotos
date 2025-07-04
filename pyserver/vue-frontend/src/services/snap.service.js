const API_URL = 'http://localhost:8000'; // Assuming your FastAPI server is running on this address

const getHeaders = () => {
  const jam = localStorage.getItem('jam');
  return {
    'Content-Type': 'application/json',
    'Preserve': jam ? jam : ''
  };
};

export const getSnaps = async () => {
  const response = await fetch(`${API_URL}/snaps/`, { headers: getHeaders() });
  if (!response.ok) {
    throw new Error('Failed to fetch snaps');
  }
  return response.json();
};

export const getAlbumSnaps = async (album_id) => {
  const response = await fetch(`${API_URL}/snaps/?where=id in (select snap_id from aopalbum_items where album_id=${album_id})&orderby=taken_date`, { headers: getHeaders() });
  if (!response.ok) {
    throw new Error('Failed to fetch album snaps');
  }
  return response.json();
};
export const getSnap = async (id) => {
  const response = await fetch(`${API_URL}/snaps/${id}`, { headers: getHeaders() });
  if (!response.ok) {
    throw new Error(`Failed to fetch snap with id ${id}`);
  }
  return response.json();
};

export const createSnap = async (snap) => {
  const response = await fetch(`${API_URL}/snaps`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify(snap),
  });
  if (!response.ok) {
    throw new Error('Failed to create snap');
  }
  return response.json();
};

export const updateSnap = async (snap) => {
  const response = await fetch(`${API_URL}/snaps`, {
    method: 'PUT',
    headers: getHeaders(),
    body: JSON.stringify(snap),
  });
  if (!response.ok) {
    throw new Error(`Failed to update snap with id ${snap.id}`);
  }
  return response.json();
};

export const deleteSnap = async (id) => {
  const response = await fetch(`${API_URL}/snaps/${id}`, {
    method: 'DELETE',
    headers: getHeaders(),
  });
  if (!response.ok) {
    throw new Error(`Failed to delete snap with id ${id}`);
  }
};
