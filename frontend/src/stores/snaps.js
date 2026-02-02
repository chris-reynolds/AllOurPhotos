/**
 * Snaps store
 * Manages photo/video snap data
 */
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api, API_URL } from '@/services/api'
import { logger } from '@/utils/logger'
import { useUIStore } from './ui'

export const useSnapsStore = defineStore('snaps', () => {
  const uiStore = useUIStore()

  // State
  const snaps = ref([])
  const currentSnap = ref(null)
  const filter = ref({
    startdate: null,
    enddate: null,
    description: '',
    ranking: null,
    albumid: null,
    orderby: 'taken_date'
  })

  // Getters
  const snapCount = computed(() => snaps.value.length)

  const filteredSnaps = computed(() => {
    let result = snaps.value

    if (filter.value.startdate) {
      result = result.filter(s => new Date(s.taken_date) >= filter.value.startdate)
    }

    if (filter.value.enddate) {
      result = result.filter(s => new Date(s.taken_date) < filter.value.enddate)
    }

    if (filter.value.description) {
      const desc = filter.value.description.toLowerCase()
      result = result.filter(s =>
        s.caption?.toLowerCase().includes(desc) ||
        s.location?.toLowerCase().includes(desc)
      )
    }

    if (filter.value.ranking) {
      result = result.filter(s => s.ranking === filter.value.ranking)
    }

    return result
  })

  // Actions
  async function fetchSnaps(where = '1=1', orderby = 'taken_date', limit = 1000) {
    try {
      logger.info('Fetching snaps', { where, orderby, limit }, 'SNAPS_STORE')
      uiStore.startLoading('Loading photos...')

      const data = await api.get('/snaps/', {
        where,
        orderby,
        limit
      })

      snaps.value = data
      logger.info(`Fetched ${data.length} snaps`, null, 'SNAPS_STORE')

      return data
    } catch (error) {
      logger.error('Failed to fetch snaps', error, 'SNAPS_STORE')
      uiStore.showError('Failed to load photos')
      throw error
    } finally {
      uiStore.stopLoading()
    }
  }

  async function fetchSnap(id) {
    try {
      logger.debug('Fetching snap', { id }, 'SNAPS_STORE')

      const data = await api.get(`/snaps/${id}`)
      currentSnap.value = data

      return data
    } catch (error) {
      logger.error('Failed to fetch snap', error, 'SNAPS_STORE')
      uiStore.showError('Failed to load photo')
      throw error
    }
  }

  async function createSnap(snap) {
    try {
      logger.info('Creating snap', { snap }, 'SNAPS_STORE')
      uiStore.startLoading('Saving photo...')

      const data = await api.post('/snaps', snap)
      snaps.value.push(data)

      uiStore.showSuccess('Photo saved successfully')
      return data
    } catch (error) {
      logger.error('Failed to create snap', error, 'SNAPS_STORE')
      uiStore.showError('Failed to save photo')
      throw error
    } finally {
      uiStore.stopLoading()
    }
  }

  async function updateSnap(snap) {
    try {
      logger.info('Updating snap', { id: snap.id }, 'SNAPS_STORE')
      uiStore.startLoading('Updating photo...')

      const data = await api.put('/snaps', snap)

      // Update in local array
      const index = snaps.value.findIndex(s => s.id === snap.id)
      if (index !== -1) {
        snaps.value[index] = data
      }

      if (currentSnap.value?.id === snap.id) {
        currentSnap.value = data
      }

      uiStore.showSuccess('Photo updated successfully')
      return data
    } catch (error) {
      logger.error('Failed to update snap', error, 'SNAPS_STORE')
      uiStore.showError('Failed to update photo')
      throw error
    } finally {
      uiStore.stopLoading()
    }
  }

  async function deleteSnap(id) {
    try {
      logger.info('Deleting snap', { id }, 'SNAPS_STORE')
      uiStore.startLoading('Deleting photo...')

      await api.delete(`/snaps/${id}`)

      // Remove from local array
      snaps.value = snaps.value.filter(s => s.id !== id)

      if (currentSnap.value?.id === id) {
        currentSnap.value = null
      }

      uiStore.showSuccess('Photo deleted successfully')
    } catch (error) {
      logger.error('Failed to delete snap', error, 'SNAPS_STORE')
      uiStore.showError('Failed to delete photo')
      throw error
    } finally {
      uiStore.stopLoading()
    }
  }

  function getThumbnailUrl(snap) {
    return `${API_URL}/photos/${snap.directory}/thumbnails/${snap.file_name}`
  }

  function getFullUrl(snap) {
    return `${API_URL}/photos/${snap.directory}/${snap.file_name}`
  }

  function setFilter(newFilter) {
    filter.value = { ...filter.value, ...newFilter }
  }

  function clearFilter() {
    filter.value = {
      startdate: null,
      enddate: null,
      description: '',
      ranking: null,
      albumid: null,
      orderby: 'taken_date'
    }
  }

  return {
    // State
    snaps,
    currentSnap,
    filter,
    // Getters
    snapCount,
    filteredSnaps,
    // Actions
    fetchSnaps,
    fetchSnap,
    createSnap,
    updateSnap,
    deleteSnap,
    getThumbnailUrl,
    getFullUrl,
    setFilter,
    clearFilter
  }
})
