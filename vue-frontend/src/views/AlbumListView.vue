<template>
  <v-container>
    <v-card>
      <v-card-title class="text-h5">Albums</v-card-title>
      <v-card-text>
        <v-text-field
          v-model="search"
          label="Filter albums"
          clearable
          class="mb-4"
        ></v-text-field>
        <v-list>
          <v-list-item v-for="album in filteredAlbums" :key="album.id" :to="`/albums/${album.id}`" class="py-0">
              <v-list-item-title>{{ album.name }}</v-list-item-title>
          </v-list-item>
        </v-list>
      </v-card-text>
    </v-card>
  </v-container>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { getAlbums } from '@/services/album.service';

const albums = ref([]);
const search = ref('');

const filteredAlbums = computed(() => {
  if (!search.value) {
    return albums.value;
  }
  return albums.value.filter(album =>
    album.name.toLowerCase().includes(search.value.toLowerCase())
  );
});

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
