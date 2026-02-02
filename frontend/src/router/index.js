/**
 * Vue Router configuration
 */
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { logger } from '@/utils/logger'

const routes = [
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/LoginView.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/',
    name: 'home',
    component: () => import('@/views/MonthGridView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/history/:year/:month',
    name: 'month-details',
    component: () => import('@/views/MonthDetailsView.vue'),
    meta: { requiresAuth: true },
    props: true
  },
  {
    path: '/snap/:id',
    name: 'snap-detail',
    component: () => import('@/views/SnapDetailView.vue'),
    meta: { requiresAuth: true },
    props: true
  },
  {
    path: '/snaps/:id',
    name: 'snap-detail-alt',
    component: () => import('@/views/SnapDetailView.vue'),
    meta: { requiresAuth: true },
    props: true
  },
  {
    path: '/albums',
    name: 'albums',
    component: () => import('@/views/AlbumListView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/album/:id',
    name: 'album-detail',
    component: () => import('@/views/AlbumDetailView.vue'),
    meta: { requiresAuth: true },
    props: true
  },
  {
    path: '/logs',
    name: 'logs',
    component: () => import('@/views/LogsView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/users',
    name: 'users',
    component: () => import('@/views/UsersView.vue'),
    meta: { requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

// Navigation guard
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()

  logger.debug('Navigation', { from: from.path, to: to.path }, 'ROUTER')

  // Check if route requires authentication
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    // Try to restore session
    const sessionRestored = await authStore.checkSession()

    if (!sessionRestored) {
      logger.info('Redirecting to login - not authenticated', null, 'ROUTER')
      next({ name: 'login', query: { redirect: to.fullPath } })
      return
    }
  }

  // Redirect to home if already authenticated and trying to access login
  if (to.name === 'login' && authStore.isAuthenticated) {
    logger.debug('Redirecting to home - already authenticated', null, 'ROUTER')
    next({ name: 'home' })
    return
  }

  next()
})

export default router
