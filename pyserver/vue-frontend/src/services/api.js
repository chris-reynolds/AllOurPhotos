import { errorStore } from '@/stores/error.store';

export const API_URL = `${window.location.protocol}//${window.location.hostname}:8000`;

const getHeaders = () => {
  const jam = localStorage.getItem('jam');
  return {
    'Content-Type': 'application/json',
    'Preserve': jam ? jam : ''
  };
};

const handleResponse = async (response) => {
  if (!response.ok) {
    const error = new Error(`HTTP error! status: ${response.status}`);
    try {
      const contentType = response.headers.get('content-type');
      if (contentType && contentType.includes('application/json')) {
        error.body = await response.json();
      } else {
        error.body = await response.text();
      }
    } catch (e) {
      // Ignore if response is not JSON or text
    }
    errorStore.addLog({ message: error.message, stack: error.stack, body: error.body });
    throw error;
  }
  const contentType = response.headers.get('content-type');
  if (contentType && contentType.includes('application/json')) {
    return response.json();
  } else {
    return response.text();
  }
};

export const recordedFetch = async (intention, targetUrl, options) => {
  try {
    console.log(`${intention} from: ${targetUrl}`);
    const response = await fetch(targetUrl, { ...options, headers: getHeaders() });
    return handleResponse(response);
  } catch (error) {
    errorStore.addLog({ message: error.message, stack: error.stack });
    throw error;
  }
};