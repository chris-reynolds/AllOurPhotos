<template>
  <div>
    <header class="toolbar">
      <h2>{{ snap?.caption || snap?.file_name }}</h2>
      <button @click="$router.back()">Back</button>
    </header>

    <div v-if="snap" class="snap-detail">
      <img :src="getFullImageUrl(snap)" :alt="snap.caption || snap.file_name" />
      <p>File Name: {{ snap.file_name }}</p>
      <p>Directory: {{ snap.directory }}</p>
      <p>Taken Date: {{ snap.taken_date }}</p>
      <p>Device: {{ snap.device_name }}</p>
      <p>Location: {{ snap.location }}</p>
      <p>Width: {{ snap.width }}</p>
      <p>Height: {{ snap.height }}</p>
    </div>
    <div v-else>
      <p>Loading snap details...</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import { getSnap } from '@/services/snap.service';

const route = useRoute();
const snap = ref(null);

const fetchSnapDetails = async (snapId) => {
  try {
    snap.value = await getSnap(snapId);
  } catch (error) {
    console.error(error);
  }
};

const getFullImageUrl = (snap) => {
  return `http://localhost:8000/photos/${snap.directory}/${snap.file_name}`;
};

onMounted(() => {
  fetchSnapDetails(route.params.id);
});

watch(
  () => route.params.id,
  (newId) => {
    fetchSnapDetails(newId);
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

.snap-detail {
  text-align: center;
}

.snap-detail img {
  max-width: 80%;
  height: auto;
  border: 1px solid #eee;
  margin-bottom: 1rem;
}
</style>
