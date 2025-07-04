<template>
  <div>
    <h1>Albums</h1>

    <table>
      <thead>
        <tr>
          <th>Name</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="album in albums" :key="album.id">
          <td>
            <RouterLink :to="`/albums/${album.id}`">{{ album.name }}</RouterLink>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
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
table {
  width: 100%;
  border-collapse: collapse;
}

th, td {
  border: 1px solid #ddd;
  padding: 8px;
}

th {
  background-color: #f2f2f2;
}
</style>