/**
 * Enhanced API service with axios interceptors,
 * structured logging, and error handling
 */
import axios from 'axios'
import { logger } from '@/utils/logger'

// Determine API base URL
const getApiUrl = () => {
  if (import.meta.env.VITE_API_URL) {
    return import.meta.env.VITE_API_URL
  }
  // Default to same host on port 8000
  const { protocol, hostname } = window.location
  return `${protocol}//${hostname}:8000`
}

export const API_URL = getApiUrl()

// Create axios instance
const apiClient = axios.create({
  baseURL: API_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// Request interceptor
apiClient.interceptors.request.use(
  (config) => {
    const startTime = Date.now()
    config.metadata = { startTime }

    // Add authentication header
    const preserve = localStorage.getItem('preserve')
    if (preserve) {
      config.headers['Preserve'] = preserve
    }

    // Log request
    logger.debug('API Request', {
      method: config.method?.toUpperCase(),
      url: config.url,
      params: config.params,
      data: config.data
    }, 'API_SERVICE')

    return config
  },
  (error) => {
    logger.error('API Request Error', error, 'API_SERVICE')
    return Promise.reject(error)
  }
)

// Response interceptor
apiClient.interceptors.response.use(
  (response) => {
    const duration = Date.now() - response.config.metadata.startTime

    // Log successful response
    logger.debug('API Response', {
      method: response.config.method?.toUpperCase(),
      url: response.config.url,
      status: response.status,
      duration: `${duration}ms`,
      dataSize: response.data ? JSON.stringify(response.data).length : 0
    }, 'API_SERVICE')

    return response
  },
  (error) => {
    // Calculate duration if metadata exists
    const duration = error.config?.metadata?.startTime
      ? Date.now() - error.config.metadata.startTime
      : null

    // Enhanced error logging
    const errorInfo = {
      method: error.config?.method?.toUpperCase(),
      url: error.config?.url,
      status: error.response?.status,
      statusText: error.response?.statusText,
      duration: duration ? `${duration}ms` : 'unknown',
      message: error.message,
      data: error.response?.data
    }

    logger.error('API Error', errorInfo, 'API_SERVICE')

    // Enhance error object for consumers
    const enhancedError = new Error(error.message)
    enhancedError.status = error.response?.status
    enhancedError.statusText = error.response?.statusText
    enhancedError.data = error.response?.data
    enhancedError.config = error.config
    enhancedError.isApiError = true

    // Handle specific status codes
    if (error.response) {
      switch (error.response.status) {
        case 401:
          logger.warn('Unauthorized - clearing session', null, 'API_SERVICE')
          localStorage.removeItem('preserve')
          localStorage.removeItem('jam')
          break
        case 403:
          logger.warn('Forbidden - insufficient permissions', null, 'API_SERVICE')
          break
        case 404:
          logger.info('Resource not found', { url: error.config?.url }, 'API_SERVICE')
          break
        case 500:
        case 502:
        case 503:
        case 504:
          logger.error('Server error', errorInfo, 'API_SERVICE')
          break
      }
    } else if (error.request) {
      // Request was made but no response received
      logger.error('Network error - no response received', {
        url: error.config?.url
      }, 'API_SERVICE')
      enhancedError.isNetworkError = true
    }

    return Promise.reject(enhancedError)
  }
)

/**
 * Generic API methods
 */
export const api = {
  /**
   * GET request
   */
  async get(url, params = {}, config = {}) {
    const response = await apiClient.get(url, { params, ...config })
    return response.data
  },

  /**
   * POST request
   */
  async post(url, data = {}, config = {}) {
    const response = await apiClient.post(url, data, config)
    return response.data
  },

  /**
   * PUT request
   */
  async put(url, data = {}, config = {}) {
    const response = await apiClient.put(url, data, config)
    return response.data
  },

  /**
   * DELETE request
   */
  async delete(url, config = {}) {
    const response = await apiClient.delete(url, config)
    return response.data
  },

  /**
   * Upload file with progress tracking
   */
  async upload(url, formData, onProgress = null) {
    const config = {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    }

    if (onProgress) {
      config.onUploadProgress = (progressEvent) => {
        const percentCompleted = Math.round(
          (progressEvent.loaded * 100) / progressEvent.total
        )
        onProgress(percentCompleted)
      }
    }

    const response = await apiClient.post(url, formData, config)
    return response.data
  }
}

// Export the axios instance for advanced use cases
export { apiClient }
