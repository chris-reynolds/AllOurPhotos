/**
 * Albums store
 * Manages album data and album items
 */
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api } from '@/services/api'
import { logger } from '@/utils/logger'
import { useUIStore } from './ui'

export const useAlbumsStore = defineStore('albums', () => {
  const uiStore = useUIStore()

  // State
  const albums = ref([])
  const currentAlbum = ref(null)
  const currentAlbumItems = ref([])

  // Getters
  const albumCount = computed(() => albums.value.length)

  const sortedAlbums = computed(() =>
    [...albums.value].sort((a, b) =>
      a.name.localeCompare(b.name)
    )
  )

  // Actions
  async function fetchAlbums(where = '1=1', orderby = 'name') {
    try {
      logger.info('Fetching albums', { where, orderby }, 'ALBUMS_STORE')
      uiStore.startLoading('Loading albums...')

      const data = await api.get('/albums/', {
        where,
        orderby
      })

      albums.value = data
      logger.info(`Fetched ${data.length} albums`, null, 'ALBUMS_STORE')

      return data
    } catch (error) {
      logger.error('Failed to fetch albums', error, 'ALBUMS_STORE')
      uiStore.showError('Failed to load albums')
      throw error
    } finally {
      uiStore.stopLoading()
    }
  }

  async function fetchAlbum(id) {
    try {
      logger.debug('Fetching album', { id }, 'ALBUMS_STORE')

      const data = await api.get(`/albums/${id}`)
      currentAlbum.value = data

      return data
    } catch (error) {
      logger.error('Failed to fetch album', error, 'ALBUMS_STORE')
      uiStore.showError('Failed to load album')
      throw error
    }
  }

  async function createAlbum(album) {
    try {
      logger.info('Creating album', { album }, 'ALBUMS_STORE')
      uiStore.startLoading('Creating album...')

      const data = await api.post('/albums', album)
      albums.value.push(data)

      uiStore.showSuccess('Album created successfully')
      return data
    } catch (error) {
      logger.error('Failed to create album', error, 'ALBUMS_STORE')
      uiStore.showError('Failed to create album')
      throw error
    } finally {
      uiStore.stopLoading()
    }
  }

  async function updateAlbum(album) {
    try {
      logger.info('Updating album', { id: album.id }, 'ALBUMS_STORE')
      uiStore.startLoading('Updating album...')

      const data = await api.put('/albums', album)

      // Update in local array
      const index = albums.value.findIndex(a => a.id === album.id)
      if (index !== -1) {
        albums.value[index] = data
      }

      if (currentAlbum.value?.id === album.id) {
        currentAlbum.value = data
      }

      uiStore.showSuccess('Album updated successfully')
      return data
    } catch (error) {
      logger.error('Failed to update album', error, 'ALBUMS_STORE')
      uiStore.showError('Failed to update album')
      throw error
    } finally {
      uiStore.stopLoading()
    }
  }

  async function deleteAlbum(id) {
    try {
      logger.info('Deleting album', { id }, 'ALBUMS_STORE')
      uiStore.startLoading('Deleting album...')

      await api.delete(`/albums/${id}`)

      // Remove from local array
      albums.value = albums.value.filter(a => a.id !== id)

      if (currentAlbum.value?.id === id) {
        currentAlbum.value = null
        currentAlbumItems.value = []
      }

      uiStore.showSuccess('Album deleted successfully')
    } catch (error) {
      logger.error('Failed to delete album', error, 'ALBUMS_STORE')
      uiStore.showError('Failed to delete album')
      throw error
    } finally {
      uiStore.stopLoading()
    }
  }

  async function fetchAlbumItems(albumId) {
    try {
      logger.debug('Fetching album items', { albumId }, 'ALBUMS_STORE')

      const data = await api.get('/album_items/', {
        where: `album_id=${albumId}`,
        orderby: 'id'
      })

      currentAlbumItems.value = data
      return data
    } catch (error) {
      logger.error('Failed to fetch album items', error, 'ALBUMS_STORE')
      throw error
    }
  }

  async function addSnapToAlbum(albumId, snapId) {
    try {
      logger.info('Adding snap to album', { albumId, snapId }, 'ALBUMS_STORE')

      const data = await api.post('/album_items', {
        album_id: albumId,
        snap_id: snapId
      })

      currentAlbumItems.value.push(data)
      uiStore.showSuccess('Photo added to album')

      return data
    } catch (error) {
      logger.error('Failed to add snap to album', error, 'ALBUMS_STORE')
      uiStore.showError('Failed to add photo to album')
      throw error
    }
  }

  async function removeSnapFromAlbum(albumItemId) {
    try {
      logger.info('Removing snap from album', { albumItemId }, 'ALBUMS_STORE')

      await api.delete(`/album_items/${albumItemId}`)

      currentAlbumItems.value = currentAlbumItems.value.filter(
        item => item.id !== albumItemId
      )

      uiStore.showSuccess('Photo removed from album')
    } catch (error) {
      logger.error('Failed to remove snap from album', error, 'ALBUMS_STORE')
      uiStore.showError('Failed to remove photo from album')
      throw error
    }
  }

  return {
    // State
    albums,
    currentAlbum,
    currentAlbumItems,
    // Getters
    albumCount,
    sortedAlbums,
    // Actions
    fetchAlbums,
    fetchAlbum,
    createAlbum,
    updateAlbum,
    deleteAlbum,
    fetchAlbumItems,
    addSnapToAlbum,
    removeSnapFromAlbum
  }
})
