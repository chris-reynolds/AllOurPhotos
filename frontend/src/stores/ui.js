/**
 * UI store
 * Manages global UI state like loading, snackbars, dialogs, errors
 */
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useUIStore = defineStore('ui', () => {
  // Loading state
  const isLoading = ref(false)
  const loadingMessage = ref('')
  const loadingTasks = ref(0)

  // Snackbar state
  const snackbar = ref({
    show: false,
    message: '',
    color: 'info',
    timeout: 3000
  })

  // Error state
  const error = ref(null)
  const errorDialog = ref(false)

  // Actions
  function startLoading(message = 'Loading...') {
    loadingTasks.value++
    isLoading.value = true
    loadingMessage.value = message
  }

  function stopLoading() {
    loadingTasks.value = Math.max(0, loadingTasks.value - 1)
    if (loadingTasks.value === 0) {
      isLoading.value = false
      loadingMessage.value = ''
    }
  }

  function showSnackbar(message, color = 'info', timeout = 3000) {
    snackbar.value = {
      show: true,
      message,
      color,
      timeout
    }
  }

  function showSuccess(message) {
    showSnackbar(message, 'success')
  }

  function showError(message) {
    showSnackbar(message, 'error', 5000)
  }

  function showWarning(message) {
    showSnackbar(message, 'warning', 4000)
  }

  function showInfo(message) {
    showSnackbar(message, 'info')
  }

  function hideSnackbar() {
    snackbar.value.show = false
  }

  function setError(err) {
    error.value = err
    errorDialog.value = true
  }

  function clearError() {
    error.value = null
    errorDialog.value = false
  }

  return {
    // State
    isLoading,
    loadingMessage,
    loadingTasks,
    snackbar,
    error,
    errorDialog,
    // Actions
    startLoading,
    stopLoading,
    showSnackbar,
    showSuccess,
    showError,
    showWarning,
    showInfo,
    hideSnackbar,
    setError,
    clearError
  }
})
