import { reactive } from 'vue';

export const errorStore = reactive({
  logs: [],
  addLog(log) {
    this.logs.push(log);
    console.log(log);
  },
  clearLogs() {
    this.logs = [];
    console.log
  },
});
