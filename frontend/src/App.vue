<template>
  <v-app>
    <!-- App Bar -->
    <v-app-bar
      v-if="authStore.isAuthenticated"
      color="primary"
      dark
      app
    >
      <v-app-bar-nav-icon @click="drawer = !drawer"></v-app-bar-nav-icon>
      <v-app-bar-title>AllOurPhotos</v-app-bar-title>

      <v-spacer></v-spacer>

      <!-- Error indicator -->
      <v-badge
        v-if="logsStore.errorCount > 0"
        :content="logsStore.errorCount"
        color="error"
        overlap
      >
        <v-btn icon @click="goToLogs">
          <v-icon>mdi-alert-circle</v-icon>
        </v-btn>
      </v-badge>

      <!-- User menu -->
      <v-menu>
        <template v-slot:activator="{ props }">
          <v-btn icon v-bind="props">
            <v-avatar color="secondary" size="32">
              {{ authStore.userInitial }}
            </v-avatar>
          </v-btn>
        </template>

        <v-list>
          <v-list-item>
            <v-list-item-title>{{ authStore.username }}</v-list-item-title>
          </v-list-item>
          <v-divider></v-divider>
          <v-list-item @click="goToLogs">
            <template v-slot:prepend>
              <v-icon>mdi-text-box</v-icon>
            </template>
            <v-list-item-title>View Logs</v-list-item-title>
          </v-list-item>
          <v-list-item @click="logout">
            <template v-slot:prepend>
              <v-icon>mdi-logout</v-icon>
            </template>
            <v-list-item-title>Logout</v-list-item-title>
          </v-list-item>
        </v-list>
      </v-menu>
    </v-app-bar>

    <!-- Navigation Drawer -->
    <v-navigation-drawer
      v-if="authStore.isAuthenticated"
      app
      v-model="drawer"
    >
      <v-list>
        <v-list-item to="/" prepend-icon="mdi-view-grid">
          <v-list-item-title>Month Grid</v-list-item-title>
        </v-list-item>

        <v-list-item to="/albums" prepend-icon="mdi-image-album">
          <v-list-item-title>Albums</v-list-item-title>
        </v-list-item>

        <v-divider class="my-2"></v-divider>

        <v-list-item to="/users" prepend-icon="mdi-account-multiple">
          <v-list-item-title>Users</v-list-item-title>
        </v-list-item>

        <v-list-item to="/logs" prepend-icon="mdi-text-box">
          <v-list-item-title>Logs</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-navigation-drawer>

    <!-- Main content -->
    <v-main>
      <!-- Global loading overlay -->
      <v-overlay
        :model-value="uiStore.isLoading"
        class="align-center justify-center"
        persistent
      >
        <v-progress-circular
          indeterminate
          size="64"
          color="primary"
        ></v-progress-circular>
        <div class="mt-4 text-h6">{{ uiStore.loadingMessage }}</div>
      </v-overlay>

      <!-- Router view -->
      <router-view></router-view>
    </v-main>

    <!-- Global snackbar -->
    <v-snackbar
      v-model="uiStore.snackbar.show"
      :color="uiStore.snackbar.color"
      :timeout="uiStore.snackbar.timeout"
      location="bottom right"
    >
      {{ uiStore.snackbar.message }}

      <template v-slot:actions>
        <v-btn
          variant="text"
          @click="uiStore.hideSnackbar()"
        >
          Close
        </v-btn>
      </template>
    </v-snackbar>

    <!-- Global error dialog -->
    <v-dialog
      v-model="uiStore.errorDialog"
      max-width="600"
    >
      <v-card>
        <v-card-title class="text-h5 error white--text">
          Error
        </v-card-title>

        <v-card-text class="pt-4">
          <div v-if="uiStore.error">
            <p><strong>Message:</strong> {{ uiStore.error.message }}</p>
            <p v-if="uiStore.error.status">
              <strong>Status:</strong> {{ uiStore.error.status }} {{ uiStore.error.statusText }}
            </p>
            <p v-if="uiStore.error.data">
              <strong>Details:</strong> {{ JSON.stringify(uiStore.error.data, null, 2) }}
            </p>
          </div>
        </v-card-text>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            @click="uiStore.clearError()"
          >
            Close
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-app>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUIStore } from '@/stores/ui'
import { useLogsStore } from '@/stores/logs'

const router = useRouter()
const authStore = useAuthStore()
const uiStore = useUIStore()
const logsStore = useLogsStore()

const drawer = ref(true)

function logout() {
  authStore.logout()
  router.push('/login')
}

function goToLogs() {
  router.push('/logs')
}
</script>

<style scoped>
/* Add any global styles here */
</style>
