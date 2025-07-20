<template>
  <v-container>
    <v-toolbar flat>
      <v-toolbar-title>Photos for {{ monthName }} {{ year }}</v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn icon @click="$router.back()">
        <v-icon>mdi-arrow-left</v-icon>
      </v-btn>
      <v-btn color="primary" @click="toggleSignOff(userStore.initial)">
        {{ isSignedOffByCurrentUser ? 'Unsign' : 'Sign' }} Off {{ userStore.initial ? `(${userStore.initial})` : '' }}
      </v-btn>
    </v-toolbar>

    <PhotoGrid :snaps="snaps" />
  </v-container>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue';
import { useRoute } from 'vue-router';
import { recordedFetch, API_URL } from '@/services/api';
import PhotoGrid from '@/components/PhotoGrid.vue';
import { monthStatusService } from '@/services/monthStatus.service';
import { userStore } from '@/stores/user.store';

const route = useRoute();
const snaps = ref([]);

const year = ref(null);
const month = ref(null);

const monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

const monthName = computed(() => {
  return month.value ? monthNames[month.value - 1] : '';
});

const yyyymmComputed = computed(() => {
  return `${year.value}${String(month.value).padStart(2, '0')}`;
});

const isSignedOffByCurrentUser = computed(() => {
  if (!userStore.initial || !yyyymmComputed.value) return false;
  const initials = monthStatusService.getInitialsForMonth(yyyymmComputed.value);
  return initials.includes(userStore.initial);
});

const fetchMonthSnaps = async (year, month) => {
  try {
    const yyyymm = `${year}${String(month).padStart(2, '0')}`;
    const data = await recordedFetch('fetch month snaps', `${API_URL}/snaps/?where=taken_date like '${yyyymm}%'`);
    snaps.value = data;
  } catch (error) {
    console.error(error);
  }
};

const toggleSignOff = (initial) => {
  if (!initial) {
    console.warn('User initial not available for sign-off.');
    return;
  }
  const yyyymm = `${year.value}${String(month.value).padStart(2, '0')}`;
  const currentInitials = monthStatusService.getInitialsForMonth(yyyymm);
  const signedOff = currentInitials.includes(initial);
  monthStatusService.toggleSignOff(yyyymm, initial, !signedOff);
};

onMounted(async () => {
  year.value = route.params.year;
  month.value = route.params.month;
  await fetchMonthSnaps(year.value, month.value);
  monthStatusService.fetchMonthlyStatus(); // Ensure status is loaded
});

watch(
  () => route.params,
  async (newParams) => {
    year.value = newParams.year;
    month.value = newParams.month;
    await fetchMonthSnaps(year.value, month.value);
    monthStatusService.fetchMonthlyStatus(); // Ensure status is reloaded on param change
  }
);
</script>
