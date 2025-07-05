<script setup>
import { ref, watch } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();
const isLoggedIn = ref(!!localStorage.getItem('jam'));

watch(() => localStorage.getItem('jam'), (newVal) => {
  isLoggedIn.value = !!newVal;
});

const logout = () => {
  localStorage.removeItem('jam');
  router.push('/login');
};
</script>

<template>
  <v-app>
    <v-app-bar app color="primary">
      <v-toolbar-title>All Our Photos</v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn text to="/">Home</v-btn>
      <v-btn text to="/albums">Albums</v-btn>
      <v-btn text to="/snaps">Snaps</v-btn>
      <v-btn text to="/users">Users</v-btn>
      <v-btn text to="/history">History</v-btn>

      <v-menu offset-y>
        <template v-slot:activator="{ props }">
          <v-btn icon v-bind="props">
            <v-icon>mdi-account-circle</v-icon>
          </v-btn>
        </template>
        <v-list>
          <v-list-item v-if="!isLoggedIn" to="/login">
            <v-list-item-title>Login</v-list-item-title>
          </v-list-item>
          <v-list-item v-else @click="logout">
            <v-list-item-title>Logout</v-list-item-title>
          </v-list-item>
        </v-list>
      </v-menu>
    </v-app-bar>

    <v-main>
      <v-container fluid>
        <RouterView />
      </v-container>
    </v-main>
  </v-app>
</template>

<style scoped>
/* No custom styles needed for the toolbar with Vuetify */
</style>
