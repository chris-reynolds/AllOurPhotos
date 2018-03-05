import Vue from 'vue'
import routes from './routes'
import axios from 'axios'
import Icon from 'vue-awesome/icons'

Vue.config.devtools = true
Vue.prototype.$http = axios;
Vue.component('icon',Icon)

const app = new Vue({
  el: '#app',
  data: {
    currentRoute: window.location.pathname
  },
  computed: {
    ViewComponent () {
      const matchingView = routes[this.currentRoute]
      console.log('Routing '+this.currentRoute+'='+matchingView)
      return matchingView
        ? require('./pages/' + matchingView + '.vue')
        : require('./pages/404.vue')
    }
  },
  render (h) {
    return h(this.ViewComponent)
  }
})

window.addEventListener('popstate', () => {
  app.currentRoute = window.location.pathname
})
