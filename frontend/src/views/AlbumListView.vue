<template>
  <v-container>
    <v-card>
      <v-card-title class="text-h5">
        Albums
        <v-spacer></v-spacer>
        <v-btn color="primary" @click="openCreateDialog">
          <v-icon left>mdi-plus</v-icon>
          New Album
        </v-btn>
      </v-card-title>

      <v-card-text>
        <!-- Search bar -->
        <v-text-field
          v-model="searchQuery"
          prepend-inner-icon="mdi-magnify"
          label="Search albums"
          clearable
          variant="outlined"
          density="compact"
          class="mb-4"
        ></v-text-field>

        <!-- Albums list -->
        <v-list v-if="filteredAlbums.length > 0">
          <v-list-item
            v-for="album in filteredAlbums"
            :key="album.id"
            @click="goToAlbum(album.id)"
            class="album-list-item"
          >
            <template v-slot:prepend>
              <v-avatar color="primary" size="48">
                <v-icon>mdi-image-album</v-icon>
              </v-avatar>
            </template>

            <v-list-item-title>{{ album.name }}</v-list-item-title>
            <v-list-item-subtitle v-if="album.description">
              {{ album.description }}
            </v-list-item-subtitle>

            <template v-slot:append>
              <v-btn
                icon="mdi-pencil"
                size="small"
                variant="text"
                @click.stop="openEditDialog(album)"
              ></v-btn>
              <v-btn
                icon="mdi-delete"
                size="small"
                variant="text"
                color="error"
                @click.stop="confirmDelete(album)"
              ></v-btn>
            </template>
          </v-list-item>
        </v-list>

        <v-alert v-else type="info" variant="tonal" class="mt-4">
          No albums found. Create your first album to get started!
        </v-alert>
      </v-card-text>
    </v-card>

    <!-- Create/Edit Dialog -->
    <v-dialog v-model="showDialog" max-width="500px">
      <v-card>
        <v-card-title>
          <span class="text-h5">{{ isEditing ? 'Edit Album' : 'Create Album' }}</span>
        </v-card-title>

        <v-card-text>
          <v-form ref="formRef">
            <v-text-field
              v-model="formData.name"
              label="Album Name"
              required
              :rules="[v => !!v || 'Album name is required']"
              variant="outlined"
            ></v-text-field>

            <v-textarea
              v-model="formData.description"
              label="Description"
              rows="3"
              variant="outlined"
            ></v-textarea>
          </v-form>
        </v-card-text>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="secondary" @click="closeDialog">Cancel</v-btn>
          <v-btn color="primary" @click="handleSubmit">
            {{ isEditing ? 'Update' : 'Create' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Delete Confirmation Dialog -->
    <v-dialog v-model="deleteDialog" max-width="400px">
      <v-card>
        <v-card-title class="text-h5">Confirm Delete</v-card-title>
        <v-card-text>
          Are you sure you want to delete the album "{{ albumToDelete?.name }}"?
          This will remove all photos from the album (but not delete the photos themselves).
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="secondary" @click="deleteDialog = false">Cancel</v-btn>
          <v-btn color="error" @click="handleDelete">Delete</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAlbumsStore } from '@/stores/albums'
import { useUIStore } from '@/stores/ui'
import { logger } from '@/utils/logger'

const router = useRouter()
const albumsStore = useAlbumsStore()
const uiStore = useUIStore()

const searchQuery = ref('')
const showDialog = ref(false)
const deleteDialog = ref(false)
const isEditing = ref(false)
const formRef = ref(null)
const formData = ref({
  id: null,
  name: '',
  description: ''
})
const albumToDelete = ref(null)

const filteredAlbums = computed(() => {
  if (!searchQuery.value) {
    return albumsStore.sortedAlbums
  }
  const query = searchQuery.value.toLowerCase()
  return albumsStore.sortedAlbums.filter(album =>
    album.name.toLowerCase().includes(query) ||
    album.description?.toLowerCase().includes(query)
  )
})

const fetchAlbums = async () => {
  try {
    await albumsStore.fetchAlbums()
  } catch (error) {
    logger.error('Failed to load albums', error, 'ALBUM_LIST')
  }
}

const openCreateDialog = () => {
  formData.value = { id: null, name: '', description: '' }
  isEditing.value = false
  showDialog.value = true
}

const openEditDialog = (album) => {
  formData.value = { ...album }
  isEditing.value = true
  showDialog.value = true
}

const closeDialog = () => {
  showDialog.value = false
  formData.value = { id: null, name: '', description: '' }
}

const handleSubmit = async () => {
  try {
    if (isEditing.value) {
      await albumsStore.updateAlbum(formData.value)
    } else {
      await albumsStore.createAlbum(formData.value)
    }
    closeDialog()
    await fetchAlbums()
  } catch (error) {
    logger.error('Failed to save album', error, 'ALBUM_LIST')
  }
}

const confirmDelete = (album) => {
  albumToDelete.value = album
  deleteDialog.value = true
}

const handleDelete = async () => {
  try {
    await albumsStore.deleteAlbum(albumToDelete.value.id)
    deleteDialog.value = false
    albumToDelete.value = null
    await fetchAlbums()
  } catch (error) {
    logger.error('Failed to delete album', error, 'ALBUM_LIST')
  }
}

const goToAlbum = (albumId) => {
  router.push({ name: 'album-detail', params: { id: albumId } })
}

onMounted(() => {
  fetchAlbums()
})
</script>

<style scoped>
.album-list-item {
  cursor: pointer;
  transition: background-color 0.2s;
}

.album-list-item:hover {
  background-color: rgba(0, 0, 0, 0.05);
}
</style>
