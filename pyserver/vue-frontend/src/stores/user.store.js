import { reactive } from 'vue';

export const userStore = reactive({
  userId: null,
  username: null,
  initial: null,

  setUser(id, username) {
    this.userId = id;
    this.username = username;
    this.initial = username ? username.charAt(0).toLowerCase() : null;
  },

  clearUser() {
    this.userId = null;
    this.username = null;
    this.initial = null;
  },
});
