<template>
  <v-container>
    <v-toolbar flat>
      <v-toolbar-title>{{ album?.name }}</v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn icon @click="$router.back()">
        <v-icon>mdi-arrow-left</v-icon>
      </v-btn>
    </v-toolbar>

    <PhotoGrid :snaps="snaps" />
  </v-container>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import { getAlbum } from '@/services/album.service';
import { getAlbumSnaps } from '@/services/snap.service';
import PhotoGrid from '@/components/PhotoGrid.vue';

const route = useRoute();
const album = ref(null);
const snaps = ref([]);

const fetchAlbumDetails = async (albumId) => {
  try {
    album.value = await getAlbum(albumId);
    snaps.value = await getAlbumSnaps(albumId);
  } catch (error) {
    console.error(error);
  }
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

