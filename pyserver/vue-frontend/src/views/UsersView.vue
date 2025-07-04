<template>
  <div>
    <h1>Users</h1>
    <button @click="showCreateForm = true">Create User</button>

    <div v-if="showCreateForm || showEditForm">
      <h2>{{ showEditForm ? 'Edit User' : 'Create User' }}</h2>
      <form @submit.prevent="showEditForm ? handleUpdateUser() : handleCreateUser()">
        <div>
          <label for="name">Name:</label>
          <input type="text" id="name" v-model="currentUser.name" required>
        </div>
        <div>
          <label for="hint">Hint:</label>
          <textarea id="hint" v-model="currentUser.hint"></textarea>
        </div>
        <button type="submit">{{ showEditForm ? 'Update' : 'Create' }}</button>
        <button @click="cancelForm">Cancel</button>
      </form>
    </div>

    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>Name</th>
          <th>Hint</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="user in users" :key="user.id">
          <td>{{ user.id }}</td>
          <td>{{ user.name }}</td>
          <td>{{ user.hint }}</td>
          <td>
            <button @click="editUser(user)">Edit</button>
            <button @click="handleDeleteUser(user.id)">Delete</button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import {
  getUsers,
  createUser,
  updateUser,
  deleteUser,
} from '@/services/user.service';

const users = ref([]);
const showCreateForm = ref(false);
const showEditForm = ref(false);
const currentUser = ref({});

const fetchUsers = async () => {
  try {
    users.value = await getUsers();
  } catch (error) {
    console.error(error);
  }
};

onMounted(fetchUsers);

const handleCreateUser = async () => {
  try {
    await createUser(currentUser.value);
    fetchUsers();
    cancelForm();
  } catch (error) {
    console.error(error);
  }
};

const handleUpdateUser = async () => {
  try {
    await updateUser(currentUser.value);
    fetchUsers();
    cancelForm();
  } catch (error) {
    console.error(error);
  }
};

const handleDeleteUser = async (id) => {
  try {
    await deleteUser(id);
    fetchUsers();
  } catch (error) {
    console.error(error);
  }
};

const editUser = (user) => {
  currentUser.value = { ...user };
  showEditForm.value = true;
};

const cancelForm = () => {
  showCreateForm.value = false;
  showEditForm.value = false;
  currentUser.value = {};
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
