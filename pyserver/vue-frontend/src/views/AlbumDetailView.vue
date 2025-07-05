<template>
  <v-container>
    <v-toolbar flat>
      <v-toolbar-title>{{ album?.name }}</v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn icon @click="$router.back()">
        <v-icon>mdi-arrow-left</v-icon>
      </v-btn>
    </v-toolbar>

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
  </v-container>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import { getAlbum } from '@/services/album.service';
import { getSnaps } from '@/services/snap.service';

const route = useRoute();
const album = ref(null);
const snaps = ref([]);

const fetchAlbumDetails = async (albumId) => {
  try {
    album.value = await getAlbum(albumId);
    snaps.value = await getSnaps(`id IN (SELECT snap_id FROM aopalbum_items WHERE album_id=${albumId})&orderby=taken_date desc`);
  } catch (error) {
    console.error(error);
  }
};

const getThumbnailUrl = (snap) => {
  return `http://localhost:8000/photos/${snap.directory}/thumbnails/${snap.file_name}`;
};

onMounted(() => {
  fetchAlbumDetails(route.params.id);
});

watch(
  () => route.params.id,
  (newId) => {
    fetchAlbumDetails(newId);
  }
);
</script>

