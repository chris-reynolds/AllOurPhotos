<script setup>
import { ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { errorStore } from '@/stores/error.store';
import { userStore } from '@/stores/user.store';

const router = useRouter();
const isLoggedIn = ref(!!localStorage.getItem('jam'));

watch(() => localStorage.getItem('jam'), (newVal) => {
  isLoggedIn.value = !!newVal;
});

const logout = () => {
  localStorage.removeItem('jam');
  isLoggedIn.value = false; // Explicitly update the reactive state
  userStore.clearUser(); // Clear user data from the store
  router.push('/login');
};
</script>

<template>
  <v-app>
    <v-app-bar app color="primary">
      <v-toolbar-title>aAll Our Photos</v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn v-if="isLoggedIn" text to="/albums">Albums</v-btn>
      <v-btn v-if="isLoggedIn" text to="/snaps">Snaps</v-btn>
      <v-btn v-if="isLoggedIn" text to="/users">Users</v-btn>
      <v-btn v-if="isLoggedIn" text to="/history">History</v-btn>
      <v-btn v-if="errorStore.logs.length > 0" text to="/errors">
        <v-icon color="red">mdi-alert-circle</v-icon>
      </v-btn>
      <!-- v-chip>{{ __BUILD_TIME__ }}</v-chip -->


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
.v-app-bar {max-height: 5em;
  min-height: 2em;
  margin: 8px px;}
.v-layout-top {height: 32px;}
</style>
