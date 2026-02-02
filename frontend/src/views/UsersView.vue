<template>
  <v-container>
    <v-card>
      <v-card-title class="text-h5">Users</v-card-title>
      <v-card-text>
        <v-btn color="primary" @click="showForm = true" class="mb-4">
          <v-icon left>mdi-plus</v-icon>
          Create User
        </v-btn>

        <v-dialog v-model="showForm" max-width="500px">
          <v-card>
            <v-card-title>
              <span class="text-h5">{{ isEditing ? 'Edit User' : 'Create User' }}</span>
            </v-card-title>
            <v-card-text>
              <v-form ref="formRef" @submit.prevent="handleSubmit">
                <v-text-field
                  v-model="formData.name"
                  label="Name"
                  required
                  :rules="[v => !!v || 'Name is required']"
                ></v-text-field>
                <v-textarea
                  v-model="formData.hint"
                  label="Hint"
                  rows="3"
                ></v-textarea>
              </v-form>
            </v-card-text>
            <v-card-actions>
              <v-spacer></v-spacer>
              <v-btn color="secondary" @click="cancelForm">Cancel</v-btn>
              <v-btn color="primary" @click="handleSubmit">
                {{ isEditing ? 'Update' : 'Create' }}
              </v-btn>
            </v-card-actions>
          </v-card>
        </v-dialog>

        <v-data-table
          :headers="headers"
          :items="usersStore.users"
          :loading="loading"
          class="elevation-1"
        >
          <template v-slot:[`item.actions`]="{ item }">
            <v-icon
              size="small"
              class="mr-2"
              @click="editUser(item)"
            >
              mdi-pencil
            </v-icon>
            <v-icon
              size="small"
              @click="confirmDelete(item)"
            >
              mdi-delete
            </v-icon>
          </template>
        </v-data-table>

        <v-dialog v-model="deleteDialog" max-width="400px">
          <v-card>
            <v-card-title class="text-h5">Confirm Delete</v-card-title>
            <v-card-text>
              Are you sure you want to delete user "{{ userToDelete?.name }}"?
            </v-card-text>
            <v-card-actions>
              <v-spacer></v-spacer>
              <v-btn color="secondary" @click="deleteDialog = false">Cancel</v-btn>
              <v-btn color="error" @click="handleDelete">Delete</v-btn>
            </v-card-actions>
          </v-card>
        </v-dialog>
      </v-card-text>
    </v-card>
  </v-container>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useUsersStore } from '@/stores/users'
import { useUIStore } from '@/stores/ui'
import { logger } from '@/utils/logger'

const usersStore = useUsersStore()
const uiStore = useUIStore()

const loading = ref(false)
const showForm = ref(false)
const deleteDialog = ref(false)
const isEditing = ref(false)
const formRef = ref(null)
const formData = ref({
  name: '',
  hint: ''
})
const userToDelete = ref(null)

const headers = [
  { title: 'ID', key: 'id', sortable: true },
  { title: 'Name', key: 'name', sortable: true },
  { title: 'Hint', key: 'hint', sortable: false },
  { title: 'Actions', key: 'actions', sortable: false }
]

const fetchUsers = async () => {
  loading.value = true
  try {
    await usersStore.fetchUsers()
  } catch (error) {
    uiStore.showError('Failed to fetch users')
  } finally {
    loading.value = false
  }
}

const handleSubmit = async () => {
  try {
    if (isEditing.value) {
      await usersStore.updateUser(formData.value)
      uiStore.showSuccess('User updated successfully')
    } else {
      await usersStore.createUser(formData.value)
      uiStore.showSuccess('User created successfully')
    }
    cancelForm()
    await fetchUsers()
  } catch (error) {
    uiStore.showError(isEditing.value ? 'Failed to update user' : 'Failed to create user')
  }
}

const editUser = (user) => {
  formData.value = { ...user }
  isEditing.value = true
  showForm.value = true
}

const confirmDelete = (user) => {
  userToDelete.value = user
  deleteDialog.value = true
}

const handleDelete = async () => {
  try {
    await usersStore.deleteUser(userToDelete.value.id)
    uiStore.showSuccess('User deleted successfully')
    deleteDialog.value = false
    userToDelete.value = null
    await fetchUsers()
  } catch (error) {
    uiStore.showError('Failed to delete user')
  }
}

const cancelForm = () => {
  showForm.value = false
  isEditing.value = false
  formData.value = {
    name: '',
    hint: ''
  }
}

onMounted(() => {
  fetchUsers()
})
</script>

<style scoped>
/* No custom styles needed with Vuetify */
</style>
