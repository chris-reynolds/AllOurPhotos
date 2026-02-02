import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api } from '@/services/api'
import { logger } from '@/utils/logger'

export const useUsersStore = defineStore('users', () => {
  // State
  const users = ref([])
  const currentUser = ref(null)

  // Getters
  const userById = computed(() => {
    return (id) => users.value.find(u => u.id === id)
  })

  // Actions
  const fetchUsers = async () => {
    try {
      logger.debug('Fetching users', null, 'USERS_STORE')
      const data = await api.get('/users', { where: '1=1' })
      users.value = data
      logger.info(`Fetched ${data.length} users`, null, 'USERS_STORE')
      return data
    } catch (error) {
      logger.error('Failed to fetch users', error, 'USERS_STORE')
      throw error
    }
  }

  const fetchUser = async (id) => {
    try {
      logger.debug('Fetching user', { id }, 'USERS_STORE')
      const data = await api.get(`/users/${id}`)
      currentUser.value = data
      return data
    } catch (error) {
      logger.error('Failed to fetch user', error, 'USERS_STORE')
      throw error
    }
  }

  const createUser = async (userData) => {
    try {
      logger.debug('Creating user', userData, 'USERS_STORE')
      const data = await api.post('/users', userData)
      users.value.push(data)
      logger.info('User created successfully', { id: data.id }, 'USERS_STORE')
      return data
    } catch (error) {
      logger.error('Failed to create user', error, 'USERS_STORE')
      throw error
    }
  }

  const updateUser = async (userData) => {
    try {
      logger.debug('Updating user', { id: userData.id }, 'USERS_STORE')
      const data = await api.put('/users', userData)
      const index = users.value.findIndex(u => u.id === userData.id)
      if (index !== -1) {
        users.value[index] = data
      }
      logger.info('User updated successfully', { id: data.id }, 'USERS_STORE')
      return data
    } catch (error) {
      logger.error('Failed to update user', error, 'USERS_STORE')
      throw error
    }
  }

  const deleteUser = async (id) => {
    try {
      logger.debug('Deleting user', { id }, 'USERS_STORE')
      await api.delete(`/users/${id}`)
      users.value = users.value.filter(u => u.id !== id)
      logger.info('User deleted successfully', { id }, 'USERS_STORE')
    } catch (error) {
      logger.error('Failed to delete user', error, 'USERS_STORE')
      throw error
    }
  }

  return {
    // State
    users,
    currentUser,

    // Getters
    userById,

    // Actions
    fetchUsers,
    fetchUser,
    createUser,
    updateUser,
    deleteUser
  }
})
