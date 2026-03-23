<template>
  <div>
    <h1>Snaps</h1>
    <button @click="showCreateForm = true">Create Snap</button>

    <div v-if="showCreateForm || showEditForm">
      <h2>{{ showEditForm ? 'Edit Snap' : 'Create Snap' }}</h2>
      <form @submit.prevent="showEditForm ? handleUpdateSnap() : handleCreateSnap()">
        <div>
          <label for="file_name">File Name:</label>
          <input type="text" id="file_name" v-model="currentSnap.file_name">
        </div>
        <div>
          <label for="caption">Caption:</label>
          <textarea id="caption" v-model="currentSnap.caption"></textarea>
        </div>
        <div>
          <label for="ranking">Ranking:</label>
          <input type="number" id="ranking" v-model="currentSnap.ranking" required>
        </div>
        <button type="submit">{{ showEditForm ? 'Update' : 'Create' }}</button>
        <button @click="cancelForm">Cancel</button>
      </form>
    </div>

    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>File Name</th>
          <th>Caption</th>
          <th>Ranking</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="snap in snaps" :key="snap.id">
          <td>{{ snap.id }}</td>
          <td>{{ snap.file_name }}</td>
          <td>{{ snap.caption }}</td>
          <td>{{ snap.ranking }}</td>
          <td>
            <button @click="editSnap(snap)">Edit</button>
            <button @click="handleDeleteSnap(snap.id)">Delete</button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import {
  getSnaps,
  createSnap,
  updateSnap,
  deleteSnap,
} from '@/services/snap.service';

const snaps = ref([]);
const showCreateForm = ref(false);
const showEditForm = ref(false);
const currentSnap = ref({});

const fetchSnaps = async () => {
  try {
    snaps.value = await getSnaps();
  } catch (error) {
    console.error(error);
  }
};

onMounted(fetchSnaps);

const handleCreateSnap = async () => {
  try {
    await createSnap(currentSnap.value);
    fetchSnaps();
    cancelForm();
  } catch (error) {
    console.error(error);
  }
};

const handleUpdateSnap = async () => {
  try {
    await updateSnap(currentSnap.value);
    fetchSnaps();
    cancelForm();
  } catch (error) {
    console.error(error);
  }
};

const handleDeleteSnap = async (id) => {
  try {
    await deleteSnap(id);
    fetchSnaps();
  } catch (error) {
    console.error(error);
  }
};

const editSnap = (snap) => {
  currentSnap.value = { ...snap };
  showEditForm.value = true;
};

const cancelForm = () => {
  showCreateForm.value = false;
  showEditForm.value = false;
  currentSnap.value = {};
};
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
