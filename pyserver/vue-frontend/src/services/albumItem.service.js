const API_URL = 'http://localhost:8000'; // Assuming your FastAPI server is running on this address

const getHeaders = () => {
  const jam = localStorage.getItem('jam');
  return {
    'Content-Type': 'application/json',
    'Preserve': jam ? jam : ''
  };
};

export const getAlbumItems = async (where = '1=1') => {
  const response = await fetch(`${API_URL}/album_items/?where=${where}`, { headers: getHeaders() });
  if (!response.ok) {
    throw new Error('Failed to fetch album items');
  }
  return response.json();
};

export const getAlbumItem = async (id) => {
  const response = await fetch(`${API_URL}/album_items/${id}`, { headers: getHeaders() });
  if (!response.ok) {
    throw new Error(`Failed to fetch album item with id ${id}`);
  }
  return response.json();
};
