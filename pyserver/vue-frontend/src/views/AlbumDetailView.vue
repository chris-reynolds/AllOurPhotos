<template>
  <div>
    <header class="toolbar">
      <h2>{{ album?.name }}</h2>
      <button @click="$router.back()">Back to Albums</button>
    </header>

    <div class="thumbnail-grid">
      <div v-for="snap in snaps" :key="snap.id" class="thumbnail-item">
        <RouterLink :to="`/snaps/${snap.id}`">
          <img :src="getThumbnailUrl(snap)" :alt="snap.caption" />
          <p>{{ snap.caption }}</p>
        </RouterLink>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import { getAlbum } from '@/services/album.service';
import { getAlbumSnaps } from '@/services/snap.service';

const route = useRoute();
const album = ref(null);
const snaps = ref([]);

const fetchAlbumDetails = async (albumId) => {
  try {
    album.value = await getAlbum(albumId);
    snaps.value = await getAlbumSnaps(albumId)
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

<style scoped>
.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: #f2f2f2;
  padding: 1rem;
  border-bottom: 1px solid #ddd;
  margin-bottom: 1rem;
}

.thumbnail-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 1rem;
}

.thumbnail-item {
  text-align: center;
  border: 1px solid #eee;
  padding: 0.5rem;
  border-radius: 5px;
}

.thumbnail-item img {
  max-width: 100%;
  height: auto;
  display: block;
  margin: 0 auto;
}
</style>
