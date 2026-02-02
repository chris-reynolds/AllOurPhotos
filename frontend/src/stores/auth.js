/**
 * Authentication store
 * Manages user session, login/logout
 */
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api } from '@/services/api'
import { logger } from '@/utils/logger'

export const useAuthStore = defineStore('auth', () => {
  // State
  const userId = ref(null)
  const username = ref(null)
  const sessionId = ref(null)
  const isAuthenticated = ref(false)
  const isLoading = ref(false)
  const error = ref(null)

  // Getters
  const userInitial = computed(() =>
    username.value ? username.value.charAt(0).toUpperCase() : ''
  )

  // Actions
  async function login(user, password, source = 'web') {
    isLoading.value = true
    error.value = null

    try {
      logger.info('Attempting login', { user, source }, 'AUTH')

      const response = await api.get(`/ses/${user}/${password}/${source}`)

      if (response.jam && parseInt(response.jam) > 0) {
        sessionId.value = response.jam

        // Store session
        const preserveData = JSON.stringify({ jam: response.jam })
        localStorage.setItem('preserve', preserveData)
        localStorage.setItem('jam', response.jam)

        // Get user details from session
        const userDetails = await api.get('/find/sessionUser', {
          session_id: response.jam
        })

        if (userDetails && userDetails.length > 0) {
          userId.value = userDetails[0].id
          username.value = userDetails[0].name
          isAuthenticated.value = true

          logger.info('Login successful', {
            userId: userId.value,
            username: username.value
          }, 'AUTH')

          return true
        } else {
          throw new Error('Failed to get user details')
        }
      } else {
        throw new Error('Invalid credentials')
      }
    } catch (err) {
      error.value = err.message || 'Login failed'
      logger.error('Login failed', err, 'AUTH')
      return false
    } finally {
      isLoading.value = false
    }
  }

  function logout() {
    logger.info('Logging out', { username: username.value }, 'AUTH')

    userId.value = null
    username.value = null
    sessionId.value = null
    isAuthenticated.value = false

    localStorage.removeItem('preserve')
    localStorage.removeItem('jam')
  }

  async function checkSession() {
    const preserve = localStorage.getItem('preserve')

    if (!preserve) {
      return false
    }

    try {
      const preserveData = JSON.parse(preserve)
      sessionId.value = preserveData.jam

      // Verify session is still valid
      const userDetails = await api.get('/find/sessionUser', {
        session_id: preserveData.jam
      })

      if (userDetails && userDetails.length > 0) {
        userId.value = userDetails[0].id
        username.value = userDetails[0].name
        isAuthenticated.value = true

        logger.info('Session restored', {
          userId: userId.value,
          username: username.value
        }, 'AUTH')

        return true
      }
    } catch (err) {
      logger.warn('Session check failed', err, 'AUTH')
      logout()
    }

    return false
  }

  return {
    // State
    userId,
    username,
    sessionId,
    isAuthenticated,
    isLoading,
    error,
    // Getters
    userInitial,
    // Actions
    login,
    logout,
    checkSession
  }
}, {
  persist: false // Don't persist to storage, we handle it manually
})
