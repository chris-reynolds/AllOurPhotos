<template>
  <v-container fluid>
    <v-toolbar flat>
      <v-btn icon @click="$router.back()">
        <v-icon>mdi-arrow-left</v-icon>
      </v-btn>
      <v-toolbar-title>Application Logs</v-toolbar-title>
      <v-spacer></v-spacer>
      <v-chip class="mr-2" color="error" v-if="logsStore.errorCount > 0">
        {{ logsStore.errorCount }} Errors
      </v-chip>
      <v-chip class="mr-2" color="warning" v-if="logsStore.warnCount > 0">
        {{ logsStore.warnCount }} Warnings
      </v-chip>
      <v-btn
        icon
        @click="logsStore.downloadLogs()"
        title="Download logs"
      >
        <v-icon>mdi-download</v-icon>
      </v-btn>
      <v-btn
        icon
        @click="logsStore.clearLogs()"
        title="Clear logs"
      >
        <v-icon>mdi-delete</v-icon>
      </v-btn>
    </v-toolbar>

    <v-row>
      <v-col cols="12">
        <v-card>
          <v-card-text>
            <!-- Filter tabs -->
            <v-tabs v-model="selectedTab">
              <v-tab value="all">All ({{ logsStore.logs.length }})</v-tab>
              <v-tab value="errors">Errors ({{ logsStore.errorCount }})</v-tab>
              <v-tab value="warnings">Warnings ({{ logsStore.warnCount }})</v-tab>
              <v-tab value="info">Info ({{ logsStore.infoLogs.length }})</v-tab>
            </v-tabs>

            <!-- Logs list -->
            <v-window v-model="selectedTab" class="mt-4">
              <v-window-item value="all">
                <log-list :logs="logsStore.logs" />
              </v-window-item>

              <v-window-item value="errors">
                <log-list :logs="logsStore.errorLogs" />
              </v-window-item>

              <v-window-item value="warnings">
                <log-list :logs="logsStore.warnLogs" />
              </v-window-item>

              <v-window-item value="info">
                <log-list :logs="logsStore.infoLogs" />
              </v-window-item>
            </v-window>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
import { ref } from 'vue'
import { useLogsStore } from '@/stores/logs'
import LogList from '@/components/LogList.vue'

const logsStore = useLogsStore()
const selectedTab = ref('all')
</script>
