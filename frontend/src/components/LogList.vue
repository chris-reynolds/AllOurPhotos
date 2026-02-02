<template>
  <v-list>
    <v-list-item
      v-for="(log, index) in logs"
      :key="index"
      :class="getLogClass(log.level)"
    >
      <template v-slot:prepend>
        <v-icon :color="getLogColor(log.level)">
          {{ getLogIcon(log.level) }}
        </v-icon>
      </template>

      <v-list-item-title>
        {{ log.message }}
      </v-list-item-title>

      <v-list-item-subtitle>
        <span class="text-caption">{{ formatTimestamp(log.timestamp) }}</span>
        <span v-if="log.context" class="ml-2 text-caption">[{{ log.context }}]</span>
      </v-list-item-subtitle>

      <template v-slot:append>
        <v-btn
          icon
          size="small"
          @click="showDetails(log)"
        >
          <v-icon>mdi-information-outline</v-icon>
        </v-btn>
      </template>
    </v-list-item>

    <v-list-item v-if="logs.length === 0">
      <v-list-item-title class="text-center text-grey">
        No logs to display
      </v-list-item-title>
    </v-list-item>
  </v-list>

  <!-- Details dialog -->
  <v-dialog v-model="detailsDialog" max-width="800">
    <v-card v-if="selectedLog">
      <v-card-title>Log Details</v-card-title>

      <v-card-text>
        <v-table>
          <tbody>
            <tr>
              <td><strong>Timestamp:</strong></td>
              <td>{{ formatTimestamp(selectedLog.timestamp) }}</td>
            </tr>
            <tr>
              <td><strong>Level:</strong></td>
              <td>
                <v-chip :color="getLogColor(selectedLog.level)" size="small">
                  {{ selectedLog.level }}
                </v-chip>
              </td>
            </tr>
            <tr>
              <td><strong>Message:</strong></td>
              <td>{{ selectedLog.message }}</td>
            </tr>
            <tr v-if="selectedLog.context">
              <td><strong>Context:</strong></td>
              <td>{{ selectedLog.context }}</td>
            </tr>
            <tr v-if="selectedLog.data">
              <td><strong>Data:</strong></td>
              <td>
                <pre>{{ JSON.stringify(selectedLog.data, null, 2) }}</pre>
              </td>
            </tr>
            <tr v-if="selectedLog.stack">
              <td><strong>Stack:</strong></td>
              <td>
                <pre class="text-caption">{{ selectedLog.stack }}</pre>
              </td>
            </tr>
          </tbody>
        </v-table>
      </v-card-text>

      <v-card-actions>
        <v-spacer></v-spacer>
        <v-btn @click="detailsDialog = false">Close</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup>
import { ref } from 'vue'

defineProps({
  logs: {
    type: Array,
    default: () => []
  }
})

const detailsDialog = ref(false)
const selectedLog = ref(null)

function getLogColor(level) {
  switch (level) {
    case 'ERROR': return 'error'
    case 'WARN': return 'warning'
    case 'INFO': return 'info'
    case 'DEBUG': return 'grey'
    default: return 'grey'
  }
}

function getLogIcon(level) {
  switch (level) {
    case 'ERROR': return 'mdi-alert-circle'
    case 'WARN': return 'mdi-alert'
    case 'INFO': return 'mdi-information'
    case 'DEBUG': return 'mdi-bug'
    default: return 'mdi-circle'
  }
}

function getLogClass(level) {
  return `log-${level.toLowerCase()}`
}

function formatTimestamp(timestamp) {
  return new Date(timestamp).toLocaleString()
}

function showDetails(log) {
  selectedLog.value = log
  detailsDialog.value = true
}
</script>

<style scoped>
.log-error {
  background-color: rgba(255, 82, 82, 0.1);
}

.log-warn {
  background-color: rgba(251, 140, 0, 0.1);
}

pre {
  white-space: pre-wrap;
  word-wrap: break-word;
  font-family: monospace;
  font-size: 0.875rem;
}
</style>
