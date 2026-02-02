<template>
  <v-toolbar dense flat class="photo-grid-toolbar">
    <v-btn icon @click="expanded = !expanded">
      <v-icon>{{ expanded ? 'mdi-chevron-up' : 'mdi-filter-variant' }}</v-icon>
    </v-btn>

    <v-expand-transition>
      <div v-show="expanded" class="toolbar-expanded-content">
        <v-text-field v-model="search.startdate" label="Start Date" type="date" dense hide-details class="mx-2"></v-text-field>
        <v-text-field v-model="search.enddate" label="End Date" type="date" dense hide-details class="mx-2"></v-text-field>
        <v-text-field v-model="search.description" label="Description" dense hide-details class="mx-2"></v-text-field>
        <v-select v-model="search.ranking" :items="[1, 2, 3, 4, 5]" label="Ranking" dense hide-details class="mx-2"></v-select>
        <v-btn icon @click="applyFilters">
          <v-icon>mdi-magnify</v-icon>
        </v-btn>

        <v-spacer></v-spacer>

        <v-slider v-model="photosPerRow" :min="1" :max="10" :step="1" label="Photos per row" class="mx-4" dense hide-details></v-slider>

        <v-btn-toggle v-model="mode" dense group mandatory>
          <v-btn value="view">
            <v-icon>mdi-image</v-icon>
          </v-btn>
          <v-btn value="select">
            <v-icon>mdi-check-box-multiple-outline</v-icon>
          </v-btn>
          <v-btn value="edit">
            <v-icon>mdi-pencil</v-icon>
          </v-btn>
        </v-btn-toggle>
      </div>
    </v-expand-transition>
  </v-toolbar>
</template>

<script setup>
import { ref, watch, defineProps, onMounted } from 'vue';

const props = defineProps({
  initialCriteria: {
    type: Object,
    default: () => ({}),
  },
});

const expanded = ref(false);
const search = ref({});
const mode = ref('view');
const photosPerRow = ref(4);

const emit = defineEmits(['filter', 'mode-change', 'photos-per-row-change']);

const applyFilters = () => {
  emit('filter', search.value);
};

watch(mode, (newMode) => {
  emit('mode-change', newMode);
});

watch(photosPerRow, (newVal) => {
  emit('photos-per-row-change', newVal);
});

onMounted(() => {
  search.value = { ...props.initialCriteria };
});
</script>

<style scoped>
.photo-grid-toolbar {
  position: sticky;
  top: 0;
  z-index: 1;
}

.toolbar-expanded-content {
  display: flex;
  align-items: center;
  width: 100%;
}
</style>
