<template>
  <v-container>
    <v-toolbar flat>
      <v-btn icon @click="$router.back()">
        <v-icon>mdi-arrow-left</v-icon>
      </v-btn>
      <v-toolbar-title>{{ album?.name || 'Album' }}</v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn icon @click="openEditAlbumDialog">
        <v-icon>mdi-pencil</v-icon>
      </v-btn>
      <v-btn color="primary" @click="openAddPhotosDialog">
        <v-icon left>mdi-plus</v-icon>
        Add Photos
      </v-btn>
    </v-toolbar>

    <!-- Album description -->
    <v-card v-if="album?.description" class="mt-3 mb-4">
      <v-card-text>{{ album.description }}</v-card-text>
    </v-card>

    <!-- Photos grid -->
    <v-card v-if="albumSnaps.length > 0">
      <v-card-text>
        <v-row>
          <v-col
            v-for="snap in albumSnaps"
            :key="snap.id"
            :cols="12 / photosPerRow"
            class="pa-1"
          >
            <v-card flat class="photo-card">
              <router-link :to="`/snap/${snap.id}`" class="photo-link">
                <v-img
                  :src="getThumbnailUrl(snap)"
                  :alt="snap.caption || snap.file_name"
                  aspect-ratio="1"
                  cover
                  class="grey-lighten-2"
                >
                  <template v-slot:placeholder>
                    <v-row class="fill-height ma-0" align="center" justify="center">
                      <v-progress-circular indeterminate></v-progress-circular>
                    </v-row>
                  </template>
                </v-img>
              </router-link>
              <v-card-actions class="pa-1">
                <v-spacer></v-spacer>
                <v-btn
                  icon="mdi-close"
                  size="small"
                  color="error"
                  @click="confirmRemovePhoto(snap)"
                ></v-btn>
              </v-card-actions>
            </v-card>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>

    <v-alert v-else type="info" variant="tonal" class="mt-4">
      No photos in this album yet. Click "Add Photos" to get started!
    </v-alert>

    <!-- Edit Album Dialog -->
    <v-dialog v-model="showEditDialog" max-width="500px">
      <v-card>
        <v-card-title>Edit Album</v-card-title>
        <v-card-text>
          <v-form ref="editFormRef">
            <v-text-field
              v-model="editFormData.name"
              label="Album Name"
              required
              :rules="[v => !!v || 'Album name is required']"
              variant="outlined"
            ></v-text-field>
            <v-textarea
              v-model="editFormData.description"
              label="Description"
              rows="3"
              variant="outlined"
            ></v-textarea>
          </v-form>
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="secondary" @click="showEditDialog = false">Cancel</v-btn>
          <v-btn color="primary" @click="handleUpdateAlbum">Update</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Add Photos Dialog -->
    <v-dialog v-model="showAddPhotosDialog" max-width="800px" scrollable>
      <v-card>
        <v-card-title>Add Photos to Album</v-card-title>
        <v-card-text>
          <!-- Date range filter -->
          <v-row>
            <v-col cols="6">
              <v-text-field
                v-model="startDate"
                label="Start Date"
                type="date"
                variant="outlined"
                density="compact"
              ></v-text-field>
            </v-col>
            <v-col cols="6">
              <v-text-field
                v-model="endDate"
                label="End Date"
                type="date"
                variant="outlined"
                density="compact"
              ></v-text-field>
            </v-col>
          </v-row>

          <v-btn color="primary" @click="fetchAvailablePhotos" class="mb-4">
            Search Photos
          </v-btn>

          <!-- Available photos grid -->
          <v-row v-if="availableSnaps.length > 0">
            <v-col
              v-for="snap in availableSnaps"
              :key="snap.id"
              cols="3"
              class="pa-1"
            >
              <v-card
                flat
                :class="{ 'selected-photo': selectedSnaps.has(snap.id) }"
                @click="togglePhotoSelection(snap)"
                class="selectable-photo"
              >
                <v-img
                  :src="getThumbnailUrl(snap)"
                  :alt="snap.caption || snap.file_name"
                  aspect-ratio="1"
                  cover
                  class="grey-lighten-2"
                >
                  <v-checkbox
                    :model-value="selectedSnaps.has(snap.id)"
                    class="selection-checkbox"
                    hide-details
                    @click.stop
                  ></v-checkbox>
                </v-img>
              </v-card>
            </v-col>
          </v-row>

          <v-alert v-else-if="searchPerformed" type="info" variant="tonal" class="mt-4">
            No photos found for the selected date range.
          </v-alert>
        </v-card-text>
        <v-card-actions>
          <v-chip v-if="selectedSnaps.size > 0" color="primary">
            {{ selectedSnaps.size }} photo(s) selected
          </v-chip>
          <v-spacer></v-spacer>
          <v-btn color="secondary" @click="closeAddPhotosDialog">Cancel</v-btn>
          <v-btn
            color="primary"
            @click="handleAddPhotos"
            :disabled="selectedSnaps.size === 0"
          >
            Add Selected
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Remove Photo Confirmation -->
    <v-dialog v-model="showRemoveDialog" max-width="400px">
      <v-card>
        <v-card-title>Remove Photo</v-card-title>
        <v-card-text>
          Are you sure you want to remove this photo from the album?
          (The photo itself will not be deleted)
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="secondary" @click="showRemoveDialog = false">Cancel</v-btn>
          <v-btn color="error" @click="handleRemovePhoto">Remove</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAlbumsStore } from '@/stores/albums'
import { useSnapsStore } from '@/stores/snaps'
import { useUIStore } from '@/stores/ui'
import { logger } from '@/utils/logger'

const route = useRoute()
const albumsStore = useAlbumsStore()
const snapsStore = useSnapsStore()
const uiStore = useUIStore()

const props = defineProps({
  id: {
    type: [String, Number],
    required: true
  }
})

const album = ref(null)
const albumItems = ref([])
const albumSnaps = ref([])
const photosPerRow = ref(4)
const showEditDialog = ref(false)
const showAddPhotosDialog = ref(false)
const showRemoveDialog = ref(false)
const editFormRef = ref(null)
const editFormData = ref({ name: '', description: '' })
const startDate = ref('')
const endDate = ref('')
const availableSnaps = ref([])
const selectedSnaps = ref(new Set())
const photoToRemove = ref(null)
const searchPerformed = ref(false)

const getThumbnailUrl = (snap) => {
  return snapsStore.getThumbnailUrl(snap)
}

const fetchAlbumData = async () => {
  try {
    logger.info('Fetching album data', { id: props.id }, 'ALBUM_DETAIL')

    // Fetch album
    album.value = await albumsStore.fetchAlbum(props.id)

    // Fetch album items
    albumItems.value = await albumsStore.fetchAlbumItems(props.id)

    // Fetch the actual snaps for the album items
    if (albumItems.value.length > 0) {
      const snapIds = albumItems.value.map(item => item.snap_id)
      const snapPromises = snapIds.map(id => snapsStore.fetchSnap(id))
      const snaps = await Promise.all(snapPromises)
      albumSnaps.value = snaps.filter(s => s != null)
    } else {
      albumSnaps.value = []
    }

    logger.info(`Loaded ${albumSnaps.value.length} photos in album`, null, 'ALBUM_DETAIL')
  } catch (error) {
    logger.error('Failed to fetch album data', error, 'ALBUM_DETAIL')
    uiStore.showError('Failed to load album')
  }
}

const openEditAlbumDialog = () => {
  editFormData.value = { ...album.value }
  showEditDialog.value = true
}

const handleUpdateAlbum = async () => {
  try {
    await albumsStore.updateAlbum(editFormData.value)
    album.value = editFormData.value
    showEditDialog.value = false
  } catch (error) {
    logger.error('Failed to update album', error, 'ALBUM_DETAIL')
  }
}

const openAddPhotosDialog = () => {
  let start, end

  // If album has photos, use date range from 1 month before earliest to 1 month after latest
  if (albumSnaps.value.length > 0) {
    const dates = albumSnaps.value
      .map(snap => new Date(snap.taken_date))
      .filter(d => !isNaN(d))
      .sort((a, b) => a - b)

    if (dates.length > 0) {
      start = new Date(dates[0])
      start.setMonth(start.getMonth() - 1)

      end = new Date(dates[dates.length - 1])
      end.setMonth(end.getMonth() + 1)
    }
  }

  // If album name starts with a year, use that year
  if (!start && album.value?.name) {
    const yearMatch = album.value.name.match(/^(19|20)\d{2}/)
    if (yearMatch) {
      const year = parseInt(yearMatch[0])
      start = new Date(year, 0, 1) // Jan 1
      end = new Date(year, 11, 31) // Dec 31
    }
  }

  // Fallback to last month if no other criteria
  if (!start) {
    end = new Date()
    start = new Date()
    start.setMonth(start.getMonth() - 1)
  }

  startDate.value = start.toISOString().split('T')[0]
  endDate.value = end.toISOString().split('T')[0]

  showAddPhotosDialog.value = true
  searchPerformed.value = false
  availableSnaps.value = []
  selectedSnaps.value = new Set()
}

const closeAddPhotosDialog = () => {
  showAddPhotosDialog.value = false
  availableSnaps.value = []
  selectedSnaps.value = new Set()
  searchPerformed.value = false
}

const fetchAvailablePhotos = async () => {
  try {
    if (!startDate.value || !endDate.value) {
      uiStore.showWarning('Please select both start and end dates')
      return
    }

    const start = new Date(startDate.value)
    const end = new Date(endDate.value)
    end.setDate(end.getDate() + 1) // Include end date

    const where = `taken_date >= '${start.toISOString()}' AND taken_date < '${end.toISOString()}' AND ranking IN (2,3)`

    const snaps = await snapsStore.fetchSnaps(where, 'taken_date', 500)

    // Filter out photos already in this album
    const existingSnapIds = new Set(albumItems.value.map(item => item.snap_id))
    availableSnaps.value = snaps.filter(snap => !existingSnapIds.has(snap.id))

    searchPerformed.value = true
    logger.info(`Found ${availableSnaps.value.length} available photos`, null, 'ALBUM_DETAIL')
  } catch (error) {
    logger.error('Failed to fetch available photos', error, 'ALBUM_DETAIL')
    uiStore.showError('Failed to load photos')
  }
}

const togglePhotoSelection = (snap) => {
  if (selectedSnaps.value.has(snap.id)) {
    selectedSnaps.value.delete(snap.id)
  } else {
    selectedSnaps.value.add(snap.id)
  }
  // Trigger reactivity
  selectedSnaps.value = new Set(selectedSnaps.value)
}

const handleAddPhotos = async () => {
  try {
    uiStore.startLoading('Adding photos to album...')

    const promises = Array.from(selectedSnaps.value).map(snapId =>
      albumsStore.addSnapToAlbum(props.id, snapId)
    )

    await Promise.all(promises)

    uiStore.showSuccess(`Added ${selectedSnaps.value.size} photo(s) to album`)
    closeAddPhotosDialog()
    await fetchAlbumData()
  } catch (error) {
    logger.error('Failed to add photos to album', error, 'ALBUM_DETAIL')
    uiStore.showError('Failed to add photos')
  } finally {
    uiStore.stopLoading()
  }
}

const confirmRemovePhoto = (snap) => {
  // Find the album item for this snap
  const albumItem = albumItems.value.find(item => item.snap_id === snap.id)
  if (albumItem) {
    photoToRemove.value = albumItem
    showRemoveDialog.value = true
  }
}

const handleRemovePhoto = async () => {
  try {
    await albumsStore.removeSnapFromAlbum(photoToRemove.value.id)
    showRemoveDialog.value = false
    photoToRemove.value = null
    await fetchAlbumData()
  } catch (error) {
    logger.error('Failed to remove photo from album', error, 'ALBUM_DETAIL')
  }
}

onMounted(() => {
  fetchAlbumData()
})
</script>

<style scoped>
.photo-link {
  text-decoration: none;
  display: block;
}

.photo-card {
  position: relative;
}

.selectable-photo {
  cursor: pointer;
  transition: opacity 0.2s;
}

.selectable-photo:hover {
  opacity: 0.8;
}

.selected-photo {
  outline: 3px solid rgb(var(--v-theme-primary));
}

.selection-checkbox {
  position: absolute;
  top: 4px;
  left: 4px;
}
</style>
