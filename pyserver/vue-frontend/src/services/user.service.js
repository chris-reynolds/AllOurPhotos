const API_URL = 'http://localhost:8000'; // Assuming your FastAPI server is running on this address

const getHeaders = () => {
  const jam = localStorage.getItem('jam');
  return {
    'Content-Type': 'application/json',
    'Preserve': jam ? jam : ''
  };
};

export const getUsers = async () => {
  const response = await fetch(`${API_URL}/users/?where=1=1`, { headers: getHeaders() });
  if (!response.ok) {
    throw new Error('Failed to fetch users');
  }
  return response.json();
};

export const getUser = async (id) => {
  const response = await fetch(`${API_URL}/users/${id}`, { headers: getHeaders() });
  if (!response.ok) {
    throw new Error(`Failed to fetch user with id ${id}`);
  }
  return response.json();
};

export const createUser = async (user) => {
  const response = await fetch(`${API_URL}/users`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify(user),
  });
  if (!response.ok) {
    throw new Error('Failed to create user');
  }
  return response.json();
};

export const updateUser = async (user) => {
  const response = await fetch(`${API_URL}/users`, {
    method: 'PUT',
    headers: getHeaders(),
    body: JSON.stringify(user),
  });
  if (!response.ok) {
    throw new Error(`Failed to update user with id ${user.id}`);
  }
  return response.json();
};

export const deleteUser = async (id) => {
  const response = await fetch(`${API_URL}/users/${id}`, {
    method: 'DELETE',
    headers: getHeaders(),
  });
  if (!response.ok) {
    throw new Error(`Failed to delete user with id ${id}`);
  }
};
