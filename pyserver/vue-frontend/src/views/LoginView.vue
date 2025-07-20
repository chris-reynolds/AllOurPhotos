<template>
  <v-container>
    <v-row justify="center">
      <v-col cols="12" sm="8" md="6">
        <v-card>
          <v-card-title class="text-h5">Login</v-card-title>
          <v-card-text>
            <v-form @submit.prevent="handleLogin">
              <v-text-field
                v-model="username"
                label="Username"
                required
                prepend-icon="mdi-account"
              ></v-text-field>
              <v-text-field
                v-model="password"
                label="Password"
                type="password"
                required
                prepend-icon="mdi-lock"
              ></v-text-field>
              <v-btn type="submit" color="primary" block class="mt-3">Login</v-btn>
            </v-form>
            <v-alert v-if="error" type="error" class="mt-3">{{ error }}</v-alert>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { userStore } from '@/stores/user.store';
import { getSessionUser } from '@/services/user.service';


const username = ref('');
const password = ref('');
const error = ref('');
const router = useRouter();

const handleLogin = async () => {
  try {
    const response = await fetch(`http://localhost:8000/ses/${username.value}/${password.value}/vue`);
    if (!response.ok) {
      throw new Error('Login failed');
    }
    const data = await response.json();
    if (data.jam < 0) {
      error.value = 'Invalid credentials';
      return;
    }
    localStorage.setItem('jam', JSON.stringify({ jam: data.jam }));

    // Fetch user details and populate the store
    const user = await getSessionUser(data.jam);
    userStore.setUser(user.id, user.username);
   
    router.push('/');
  } catch (err) {
    error.value = (err).message;
  }
};
</script>