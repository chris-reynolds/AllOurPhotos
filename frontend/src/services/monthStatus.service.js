/**
 * Month status service
 * Manages month sign-off status
 */
import { reactive } from 'vue'
import { api, API_URL } from './api'
import { logger } from '@/utils/logger'

export const monthStatusService = reactive({
  monthlyStatus: new Map(),
  hasLoaded: false,

  async fetchMonthlyStatus(force = false) {
    if (this.hasLoaded && !force) {
      return
    }
    try {
      logger.debug('Fetching monthly status', null, 'MONTH_STATUS')
      const response = await fetch(`${API_URL}/photos/monthly.txt`)
      const textContent = await response.text()
      this.parseMonthlyStatus(textContent)
      this.hasLoaded = true
    } catch (error) {
      logger.warn('Failed to fetch monthly status', error, 'MONTH_STATUS')
    }
  },

  parseMonthlyStatus(textContent) {
    this.monthlyStatus.clear()
    const lines = textContent.split('\n')
    lines.forEach(line => {
      const trimmedLine = line.trim()
      if (trimmedLine) {
        const [yyyymm, initials] = trimmedLine.split('=')
        if (yyyymm && initials) {
          this.monthlyStatus.set(yyyymm, initials)
        }
      }
    })
    logger.debug('Parsed monthly status', { count: this.monthlyStatus.size }, 'MONTH_STATUS')
  },

  getInitialsForMonth(yyyymm) {
    return this.monthlyStatus.get(yyyymm) || ''
  },

  async toggleSignOff(yyyymm, initial, signedOff) {
    await this.fetchMonthlyStatus(true)
    let currentInitials = this.getInitialsForMonth(yyyymm)
    let newInitials

    if (signedOff) {
      // Add initial if not already present
      if (!currentInitials.includes(initial)) {
        newInitials = (currentInitials + initial).split('').sort().join('')
      } else {
        newInitials = currentInitials
      }
    } else {
      // Remove initial if present
      newInitials = currentInitials.replace(initial, '')
    }

    this.monthlyStatus.set(yyyymm, newInitials)

    // Convert map to file content string
    let fileContent = ''
    this.monthlyStatus.forEach((value, key) => {
      fileContent += `${key}=${value}\n`
    })

    try {
      logger.info('Updating monthly status', { yyyymm, initial, signedOff }, 'MONTH_STATUS')
      const response = await fetch(`${API_URL}/photos/monthly.txt`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'text/plain',
        },
        body: fileContent,
      })

      if (!response.ok) {
        throw new Error('Failed to update monthly status')
      }

      logger.info(`Successfully updated sign-off for ${yyyymm}`, null, 'MONTH_STATUS')
    } catch (error) {
      logger.error('Failed to update monthly status', error, 'MONTH_STATUS')
      // Revert local change if API call fails
      this.monthlyStatus.set(yyyymm, currentInitials)
      throw error
    }
  },
})
