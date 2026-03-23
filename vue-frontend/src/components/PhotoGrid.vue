<template>
  <div>
    <PhotoGridToolbar
      :initial-criteria="criteria"
      @filter="handleFilter"
      @mode-change="handleModeChange"
      @photos-per-row-change="handlePhotosPerRowChange"
    />
    <v-row>
      <v-col
        v-for="snap in filteredSnaps"
        :key="snap.id"
        :cols="12 / photosPerRow"
        class="d-flex child-flex pa-0"
      >
        <PhotoTile
          :snap="snap"
          :mode="currentMode"
          v-model:selected="selectedSnaps[snap.id]"
        />
      </v-col>
    </v-row>
  </div>
</template>

<script setup>
import { defineProps, ref, computed, watch } from 'vue';
import PhotoGridToolbar from './PhotoGridToolbar.vue';
import PhotoTile from './PhotoTile.vue';
import { filterSnaps as filterSnapsService } from '@/services/snap.service';

const props = defineProps({
  snaps: {
    type: Array,
    required: true,
  },
  criteria: {
    type: Object,
    default: () => ({}),
  },
});

const filteredSnaps = ref(props.snaps);
const currentMode = ref('view');
const photosPerRow = ref(4);
const selectedSnaps = ref({});

const handleFilter = async (filter) => {
  filteredSnaps.value = await filterSnapsService(filter);
};

const handleModeChange = (newMode) => {
  currentMode.value = newMode;
  if (newMode !== 'edit') {
    selectedSnaps.value = {};
  }
};

const handlePhotosPerRowChange = (newVal) => {
  photosPerRow.value = newVal;
};

watch(() => props.snaps, (newSnaps) => {
  filteredSnaps.value = newSnaps;
});

</script>

<style scoped>
/* Add any specific styles for the photo grid here if needed */
</style>
