<template>
  <v-container>
    <v-toolbar flat>
      <v-toolbar-title>{{ snap?.caption || snap?.file_name }}</v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn icon @click="$router.back()">
        <v-icon>mdi-arrow-left</v-icon>
      </v-btn>
    </v-toolbar>

    <v-card v-if="snap" class="mt-3">
      <v-img
        :src="fullImageUrl"
        :alt="snap.caption || snap.file_name"
        class="white--text align-end"
        gradient="to bottom, rgba(0,0,0,.1), rgba(0,0,0,.5)"
        height="400px"
      >
        <v-card-title class="text-h6">{{ snap.caption || snap.file_name }}</v-card-title>
      </v-img>

      <v-card-text>
        <v-list density="compact">
          <v-list-item>
            <v-list-item-title>File Name:</v-list-item-title>
            <v-list-item-subtitle>{{ snap.file_name }}</v-list-item-subtitle>
          </v-list-item>
          <v-list-item>
            <v-list-item-title>Directory:</v-list-item-title>
            <v-list-item-subtitle>{{ snap.directory }}</v-list-item-subtitle>
          </v-list-item>
          <v-list-item>
            <v-list-item-title>Taken Date:</v-list-item-title>
            <v-list-item-subtitle>{{ formatDate(snap.taken_date) }}</v-list-item-subtitle>
          </v-list-item>
          <v-list-item>
            <v-list-item-title>Device:</v-list-item-title>
            <v-list-item-subtitle>{{ snap.device_name }}</v-list-item-subtitle>
          </v-list-item>
          <v-list-item v-if="snap.location">
            <v-list-item-title>Location:</v-list-item-title>
            <v-list-item-subtitle>{{ snap.location }}</v-list-item-subtitle>
          </v-list-item>
          <v-list-item>
            <v-list-item-title>Dimensions:</v-list-item-title>
            <v-list-item-subtitle>{{ snap.width }}x{{ snap.height }}</v-list-item-subtitle>
          </v-list-item>
        </v-list>
      </v-card-text>
    </v-card>
    <div v-else>
      <v-progress-circular indeterminate></v-progress-circular>
      <p>Loading snap details...</p>
    </div>
  </v-container>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useSnapsStore } from '@/stores/snaps'
import { logger } from '@/utils/logger'

const route = useRoute()
const snapsStore = useSnapsStore()
const snap = ref(null)

const fullImageUrl = computed(() => {
  return snap.value ? snapsStore.getFullUrl(snap.value) : ''
})

const fetchSnapDetails = async (snapId) => {
  try {
    logger.debug('Fetching snap details', { id: snapId }, 'SNAP_DETAIL')
    snap.value = await snapsStore.fetchSnap(snapId)
  } catch (error) {
    logger.error('Failed to fetch snap details', error, 'SNAP_DETAIL')
  }
}

const formatDate = (dateStr) => {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleString()
}

onMounted(() => {
  fetchSnapDetails(route.params.id)
})

watch(
  () => route.params.id,
  (newId) => {
    fetchSnapDetails(newId)
  }
)
</script>

<style scoped>
/* No custom styles needed with Vuetify */
</style>
