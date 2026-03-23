<template>
  <router-link :to="`/snaps/${snap.id}`">
    <v-card flat tile class="d-flex flex-column photo-tile">
      <v-img
        :src="getThumbnailUrl(snap)"
        :alt="snap.caption || snap.file_name"
        aspect-ratio="1"
        class="grey lighten-2"
      >
        <template v-slot:placeholder>
          <v-row class="fill-height ma-0" align="center" justify="center">
            <v-progress-circular
              indeterminate
              color="grey lighten-5"
            ></v-progress-circular>
          </v-row>
        </template>
        <v-checkbox
          v-if="mode === 'edit'"
          :model-value="selected"
          @update:modelValue="$emit('update:selected', $event)"
          class="selection-checkbox"
          hide-details
        ></v-checkbox>
      </v-img>
    </v-card>
  </router-link>
</template>

<script setup>
import { defineProps, defineEmits } from 'vue';
import { getThumbnailUrl } from '@/services/snap.service';

const props = defineProps({
  snap: {
    type: Object,
    required: true,
  },
  mode: {
    type: String,
    default: 'view',
  },
  selected: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['update:selected']);
</script>

<style scoped>
.photo-tile {
  position: relative;
}

.selection-checkbox {
  position: absolute;
  top: 0;
  left: 0;
  margin: 4px;
  background-color: rgba(255, 255, 255, 0.7);
  border-radius: 50%;
}
</style>
