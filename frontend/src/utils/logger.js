/**
 * Centralized logging utility
 * Provides structured logging with different levels and persistence
 */

const LOG_LEVELS = {
  DEBUG: 0,
  INFO: 1,
  WARN: 2,
  ERROR: 3
}

const LOG_LEVEL_NAMES = ['DEBUG', 'INFO', 'WARN', 'ERROR']

class Logger {
  constructor() {
    this.logs = []
    this.maxLogs = 1000
    this.currentLevel = import.meta.env.PROD ? LOG_LEVELS.INFO : LOG_LEVELS.DEBUG
    this.listeners = []
  }

  /**
   * Set the minimum log level
   */
  setLevel(level) {
    this.currentLevel = level
  }

  /**
   * Add a listener for log events
   */
  addListener(callback) {
    this.listeners.push(callback)
  }

  /**
   * Remove a listener
   */
  removeListener(callback) {
    this.listeners = this.listeners.filter(l => l !== callback)
  }

  /**
   * Core logging method
   */
  log(level, message, data = null, context = null) {
    if (level < this.currentLevel) return

    const logEntry = {
      timestamp: new Date().toISOString(),
      level: LOG_LEVEL_NAMES[level],
      message,
      data,
      context,
      stack: level === LOG_LEVELS.ERROR ? new Error().stack : null
    }

    // Add to in-memory logs
    this.logs.push(logEntry)
    if (this.logs.length > this.maxLogs) {
      this.logs.shift()
    }

    // Console output with appropriate method
    const consoleMethod = level === LOG_LEVELS.ERROR ? 'error'
                        : level === LOG_LEVELS.WARN ? 'warn'
                        : level === LOG_LEVELS.INFO ? 'info'
                        : 'log'

    const prefix = `[${logEntry.timestamp}] [${logEntry.level}]`
    if (data) {
      console[consoleMethod](prefix, message, data)
    } else {
      console[consoleMethod](prefix, message)
    }

    // Notify listeners
    this.listeners.forEach(listener => listener(logEntry))

    return logEntry
  }

  /**
   * Convenience methods
   */
  debug(message, data, context) {
    return this.log(LOG_LEVELS.DEBUG, message, data, context)
  }

  info(message, data, context) {
    return this.log(LOG_LEVELS.INFO, message, data, context)
  }

  warn(message, data, context) {
    return this.log(LOG_LEVELS.WARN, message, data, context)
  }

  error(message, data, context) {
    return this.log(LOG_LEVELS.ERROR, message, data, context)
  }

  /**
   * Get all logs or filtered by level
   */
  getLogs(level = null) {
    if (level === null) return this.logs
    return this.logs.filter(log => log.level === LOG_LEVEL_NAMES[level])
  }

  /**
   * Clear all logs
   */
  clear() {
    this.logs = []
  }

  /**
   * Export logs as JSON
   */
  export() {
    return JSON.stringify(this.logs, null, 2)
  }
}

// Export singleton instance
export const logger = new Logger()
export { LOG_LEVELS }
