<template>
  <router-link :to="`/snap/${snap.id}`" class="photo-link">
    <v-card flat class="photo-tile">
      <v-img
        :src="thumbnailUrl"
        :alt="snap.caption || snap.file_name"
        aspect-ratio="1"
        cover
        class="grey-lighten-2"
      >
        <template v-slot:placeholder>
          <v-row class="fill-height ma-0" align="center" justify="center">
            <v-progress-circular
              indeterminate
              color="grey-lighten-5"
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
import { computed } from 'vue'
import { useSnapsStore } from '@/stores/snaps'

const props = defineProps({
  snap: {
    type: Object,
    required: true
  },
  mode: {
    type: String,
    default: 'view'
  },
  selected: {
    type: Boolean,
    default: false
  }
})

defineEmits(['update:selected'])

const snapsStore = useSnapsStore()
const thumbnailUrl = computed(() => snapsStore.getThumbnailUrl(props.snap))
</script>

<style scoped>
.photo-link {
  text-decoration: none;
  display: block;
  width: 100%;
}

.photo-tile {
  position: relative;
  width: 100%;
  height: 100%;
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
