<template>
  <v-row dense>
    <v-col
      v-for="snap in snaps"
      :key="snap.id"
      cols="auto"
      class="d-flex child-flex"
    >
      <v-card flat tile class="d-flex flex-column">
        <router-link :to="`/snaps/${snap.id}`">
          <v-img
            :src="getThumbnailUrl(snap)"
            :alt="snap.caption || snap.file_name"
            aspect-ratio="1"
            class="grey lighten-2"
          >
            <template v-slot:placeholder>
              <v-row class="fill-height ma-0" align="center" justify="center">
                <v-progress-circular
                  indeterminate
                  color="grey lighten-5"
                ></v-progress-circular>
              </v-row>
            </template>
          </v-img>
        </router-link>
        <v-card-text class="text-center py-1">{{ snap.caption || snap.file_name }}</v-card-text>
      </v-card>
    </v-col>
  </v-row>
</template>

<script setup>
import { defineProps } from 'vue';
import { API_URL } from '@/services/api';

const props = defineProps({
  snaps: {
    type: Array,
    required: true,
  },
});

const getThumbnailUrl = (snap) => {
  return `${API_URL}/photos/${snap.directory}/thumbnails/${snap.file_name}`;
};
</script>

<style scoped>
/* Add any specific styles for the photo grid here if needed */
</style>
