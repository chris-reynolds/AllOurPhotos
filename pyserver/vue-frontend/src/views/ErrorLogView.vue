<template>
  <v-container>
    <v-card>
      <v-card-title class="text-h5">Error Log</v-card-title>
      <v-card-text>
        <v-list>
          <v-list-item v-for="(log, index) in errorStore.logs" :key="index">
            <v-list-item-content>
              <v-list-item-title>{{ log.message }}</v-list-item-title>
              <v-list-item-subtitle>{{ log.stack }}</v-list-item-subtitle>
            </v-list-item-content>
          </v-list-item>
        </v-list>
      </v-card-text>
      <v-card-actions>
        <v-spacer></v-spacer>
        <v-btn color="primary" @click="errorStore.clearLogs()">Clear</v-btn>
      </v-card-actions>
    </v-card>
  </v-container>
</template>

<script setup>
import { errorStore } from '@/stores/error.store';
</script>
