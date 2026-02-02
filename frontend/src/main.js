/**
 * Main application entry point
 */
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate'
import App from './App.vue'
import router from './router'
import vuetify from './plugins/vuetify'
import { logger } from './utils/logger'

// Initialize Pinia
const pinia = createPinia()
pinia.use(piniaPluginPersistedstate)

// Create app
const app = createApp(App)

// Use plugins
app.use(pinia)
app.use(router)
app.use(vuetify)

// Global error handler
app.config.errorHandler = (err, instance, info) => {
  logger.error('Global error', {
    message: err.message,
    stack: err.stack,
    info,
    component: instance?.$options?.name
  }, 'APP')
}

// Log app initialization
logger.info('AllOurPhotos frontend starting', {
  environment: import.meta.env.MODE,
  version: '1.0.0'
}, 'APP')

// Mount app
app.mount('#app')
