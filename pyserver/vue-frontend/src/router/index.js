import { createRouter, createWebHistory } from 'vue-router'
import AlbumListView from '../views/AlbumListView.vue'
import AlbumDetailView from '../views/AlbumDetailView.vue'
import SnapsView from '../views/SnapsView.vue'
import SnapDetailView from '../views/SnapDetailView.vue'
import UsersView from '../views/UsersView.vue'
import MonthGridView from '../views/MonthGridView.vue'
import LoginView from '../views/LoginView.vue'
import ErrorLogView from '../views/ErrorLogView.vue'
import MonthDetailsView from '../views/MonthDetailsView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      redirect: '/albums',
      meta: { requiresAuth: true }
    },
    {
      path: '/albums',
      name: 'albums',
      component: AlbumListView,
      meta: { requiresAuth: true }
    },
    {
      path: '/albums/:id',
      name: 'album-detail',
      component: AlbumDetailView,
      props: true,
      meta: { requiresAuth: true }
    },
    {
      path: '/snaps',
      name: 'snaps',
      component: SnapsView,
      meta: { requiresAuth: true }
    },
    {
      path: '/snaps/:id',
      name: 'snap-detail',
      component: SnapDetailView,
      props: true,
      meta: { requiresAuth: true }
    },
    {
      path: '/users',
      name: 'users',
      component: UsersView,
      meta: { requiresAuth: true }
    },
    {
      path: '/history',
      name: 'history',
      component: MonthGridView,
      meta: { requiresAuth: true }
    },
    {
      path: '/history/:year/:month',
      name: 'month-details',
      component: MonthDetailsView,
      props: true,
      meta: { requiresAuth: true }
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView
    },
    {
      path: '/errors',
      name: 'errors',
      component: ErrorLogView
    }
  ]
})

router.beforeEach((to, from, next) => {
  const loggedIn = localStorage.getItem('jam');

  if (to.matched.some(record => record.meta.requiresAuth) && !loggedIn) {
    next('/login');
  } else {
    next();
  }
});

export default router
