<template>
  <v-container>
    <v-card>
      <v-card-title class="text-h5">Albums</v-card-title>
      <v-card-text>
        <v-list dense>
          <v-list-item v-for="album in albums" :key="album.id" :to="`/albums/${album.id}`">
            <v-list-item-content>
              <v-list-item-title>{{ album.name }}</v-list-item-title>
            </v-list-item-content>
          </v-list-item>
        </v-list>
      </v-card-text>
    </v-card>
  </v-container>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { getAlbums } from '@/services/album.service';

const albums = ref([]);

const fetchAlbums = async () => {
  try {
    albums.value = await getAlbums('name desc');
  } catch (error) {
    console.error(error);
  }
};

onMounted(fetchAlbums);
</script>

<style scoped>
/* No custom styles needed with Vuetify */
</style>
