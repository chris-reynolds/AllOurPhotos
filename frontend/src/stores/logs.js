/**
 * Logs store
 * Centralized storage for application logs
 * Integrates with the logger utility
 */
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { logger, LOG_LEVELS } from '@/utils/logger'

export const useLogsStore = defineStore('logs', () => {
  // State
  const logs = ref([])
  const maxLogs = ref(500)

  // Getters
  const errorLogs = computed(() =>
    logs.value.filter(log => log.level === 'ERROR')
  )

  const warnLogs = computed(() =>
    logs.value.filter(log => log.level === 'WARN')
  )

  const infoLogs = computed(() =>
    logs.value.filter(log => log.level === 'INFO')
  )

  const recentLogs = computed(() =>
    logs.value.slice(-50)
  )

  const errorCount = computed(() => errorLogs.value.length)
  const warnCount = computed(() => warnLogs.value.length)

  // Actions
  function addLog(logEntry) {
    logs.value.push(logEntry)

    // Trim if exceeds max
    if (logs.value.length > maxLogs.value) {
      logs.value = logs.value.slice(-maxLogs.value)
    }
  }

  function clearLogs() {
    logs.value = []
    logger.clear()
  }

  function exportLogs() {
    return JSON.stringify(logs.value, null, 2)
  }

  function downloadLogs() {
    const dataStr = exportLogs()
    const dataBlob = new Blob([dataStr], { type: 'application/json' })
    const url = URL.createObjectURL(dataBlob)
    const link = document.createElement('a')
    link.href = url
    link.download = `allourphotos-logs-${new Date().toISOString()}.json`
    link.click()
    URL.revokeObjectURL(url)
  }

  // Initialize listener to sync with logger
  logger.addListener(addLog)

  return {
    // State
    logs,
    maxLogs,
    // Getters
    errorLogs,
    warnLogs,
    infoLogs,
    recentLogs,
    errorCount,
    warnCount,
    // Actions
    addLog,
    clearLogs,
    exportLogs,
    downloadLogs
  }
})
