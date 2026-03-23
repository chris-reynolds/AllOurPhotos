import { API_URL, recordedFetch } from './api';

export const getUsers = async () => {
  const targetUrl = `${API_URL}/users/?where=1=1`;
  return recordedFetch('get users', targetUrl);
};

export const getUser = async (id) => {
  const targetUrl = `${API_URL}/users/${id}`;
  return recordedFetch('get user', targetUrl);
};

export const getSessionUser = async (session_id) => {
  const targetUrl = `${API_URL}/find/sessionUser?session_id=${session_id}`;
  return recordedFetch('get sessionUser', targetUrl);
};
export const createUser = async (user) => {
  const targetUrl = `${API_URL}/users`;
  return recordedFetch('create user', targetUrl, {
    method: 'POST',
    body: JSON.stringify(user),
  });
};

export const updateUser = async (user) => {
  const targetUrl = `${API_URL}/users`;
  return recordedFetch('update user', targetUrl, {
    method: 'PUT',
    body: JSON.stringify(user),
  });
};

export const deleteUser = async (id) => {
  const targetUrl = `${API_URL}/users/${id}`;
  return recordedFetch('delete user', targetUrl, {
    method: 'DELETE',
  });
};
