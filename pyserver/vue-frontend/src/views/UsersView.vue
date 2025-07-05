<template>
  <v-container>
    <v-card>
      <v-card-title class="text-h5">Users</v-card-title>
      <v-card-text>
        <v-btn color="primary" @click="showCreateForm = true">Create User</v-btn>

        <v-form v-if="showCreateForm || showEditForm" @submit.prevent="showEditForm ? handleUpdateUser() : handleCreateUser()">
          <v-text-field v-model="currentUser.name" label="Name" required></v-text-field>
          <v-textarea v-model="currentUser.hint" label="Hint"></v-textarea>
          <v-btn type="submit" color="primary">{{ showEditForm ? 'Update' : 'Create' }}</v-btn>
          <v-btn color="secondary" @click="cancelForm">Cancel</v-btn>
        </v-form>

        <v-data-table
          :headers="headers"
          :items="users"
          class="elevation-1 mt-3"
        >
          <template v-slot:item.actions="{ item }">
            <v-icon small class="mr-2" @click="editUser(item)">mdi-pencil</v-icon>
            <v-icon small @click="handleDeleteUser(item.id)">mdi-delete</v-icon>
          </template>
        </v-data-table>
      </v-card-text>
    </v-card>
  </v-container>
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

const headers = [
  { title: 'ID', value: 'id' },
  { title: 'Name', value: 'name' },
  { title: 'Hint', value: 'hint' },
  { title: 'Actions', value: 'actions', sortable: false },
];

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
  showCreateForm.value = true; // Show form for editing
};

const cancelForm = () => {
  showCreateForm.value = false;
  showEditForm.value = false;
  currentUser.value = {};
};
</script>

<style scoped>
/* No custom styles needed with Vuetify */
</style>