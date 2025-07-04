<template>
  <div>
    <h1>Login</h1>
    <form @submit.prevent="handleLogin">
      <div>
        <label for="username">Username:</label>
        <input type="text" id="username" v-model="username" required>
      </div>
      <div>
        <label for="password">Password:</label>
        <input type="password" id="password" v-model="password" required>
      </div>
      <button type="submit">Login</button>
    </form>
    <p v-if="error">{{ error }}</p>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';

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
    router.push('/');
  } catch (err) {
    error.value = (err).message;
  }
};
</script>
