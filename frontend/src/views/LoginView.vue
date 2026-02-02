<template>
  <v-container fluid fill-height class="login-container">
    <v-row align="center" justify="center">
      <v-col cols="12" sm="8" md="4">
        <v-card elevation="8">
          <v-card-title class="text-h4 text-center py-8">
            AllOurPhotos
          </v-card-title>

          <v-card-text>
            <v-form ref="loginForm" v-model="valid" @submit.prevent="handleLogin">
              <v-text-field
                v-model="username"
                label="Username"
                prepend-icon="mdi-account"
                :rules="[rules.required]"
                required
                autofocus
              ></v-text-field>

              <v-text-field
                v-model="password"
                label="Password"
                prepend-icon="mdi-lock"
                type="password"
                :rules="[rules.required]"
                required
              ></v-text-field>

              <v-alert
                v-if="authStore.error"
                type="error"
                class="mt-4"
                dismissible
              >
                {{ authStore.error }}
              </v-alert>

              <v-btn
                type="submit"
                color="primary"
                block
                size="large"
                class="mt-6"
                :loading="authStore.isLoading"
                :disabled="!valid"
              >
                Login
              </v-btn>
            </v-form>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const username = ref('')
const password = ref('')
const valid = ref(false)
const loginForm = ref(null)

const rules = {
  required: value => !!value || 'Required field'
}

async function handleLogin() {
  const success = await authStore.login(username.value, password.value)

  if (success) {
    // Redirect to original destination or home
    const redirect = route.query.redirect || '/'
    router.push(redirect)
  }
}
</script>

<style scoped>
.login-container {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}
</style>
