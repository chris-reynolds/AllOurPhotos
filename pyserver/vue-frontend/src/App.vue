<script setup>
import { ref, computed, watch } from 'vue';
import { RouterView, useRouter } from 'vue-router';

const router = useRouter();
const isLoggedIn = ref(!!localStorage.getItem('jam'));
const showAuthLinks = ref(false);

watch(() => localStorage.getItem('jam'), (newVal) => {
  isLoggedIn.value = !!newVal;
});

const logout = () => {
  localStorage.removeItem('jam');
  router.push('/login');
};

const toggleAuthLinks = () => {
  showAuthLinks.value = !showAuthLinks.value;
};
</script>

<template>
  <header class="toolbar">
    <div class="toolbar-left">
      <nav>
        <RouterLink to="/">Home</RouterLink>
        <RouterLink to="/albums">Albums</RouterLink>
        <RouterLink to="/snaps">Snaps</RouterLink>
        <RouterLink to="/users">Users</RouterLink>
      </nav>
    </div>
    <div class="toolbar-right">
      <div class="person-icon" @click="toggleAuthLinks">
        &#128100; <!-- Unicode for person icon -->
      </div>
      <nav v-if="showAuthLinks" class="auth-links">
        <RouterLink v-if="!isLoggedIn" to="/login">Login</RouterLink>
        <a v-else href="#" @click="logout">Logout</a>
      </nav>
    </div>
  </header>

  <RouterView />
</template>

<style scoped>
.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: #f2f2f2;
  padding: 1rem;
  border-bottom: 1px solid #ddd;
}

.toolbar-left nav a {
  margin-right: 1rem;
}

.toolbar-right {
  position: relative;
}

.person-icon {
  font-size: 2rem;
  cursor: pointer;
}

.auth-links {
  position: absolute;
  top: 100%;
  right: 0;
  background-color: #f2f2f2;
  border: 1px solid #ddd;
  padding: 0.5rem;
  display: flex;
  flex-direction: column;
  z-index: 1000;
}

.auth-links a {
  padding: 0.5rem;
  white-space: nowrap;
}

/* Existing styles, potentially modified or removed */
header {
  line-height: 1.5;
  max-height: 100vh;
}

nav {
  font-size: 12px;
  text-align: center;
  margin-top: 0;
}

nav a.router-link-exact-active {
  color: var(--color-text);
}

nav a.router-link-exact-active:hover {
  background-color: transparent;
}

nav a {
  display: inline-block;
  padding: 0 1rem;
  border-left: 1px solid var(--color-border);
}

nav a:first-of-type {
  border: 0;
}

@media (min-width: 1024px) {
  header {
    display: flex;
    place-items: center;
    padding-right: calc(var(--section-gap) / 2);
  }

  header .wrapper {
    display: flex;
    place-items: flex-start;
    flex-wrap: wrap;
  }

  nav {
    text-align: left;
    margin-left: -1rem;
    font-size: 1rem;

    padding: 1rem 0;
    margin-top: 1rem;
  }
}
</style>