<template>
  <v-container>
    <v-card>
      <v-card-title class="text-h5">Photo History by Month</v-card-title>
      <v-card-text>
        <div class="month-grid">
          <div class="grid-header year-column">Year</div>
          <div class="grid-header">Jan</div>
          <div class="grid-header">Feb</div>
          <div class="grid-header">Mar</div>
          <div class="grid-header">Apr</div>
          <div class="grid-header">May</div>
          <div class="grid-header">Jun</div>
          <div class="grid-header">Jul</div>
          <div class="grid-header">Aug</div>
          <div class="grid-header">Sep</div>
          <div class="grid-header">Oct</div>
          <div class="grid-header">Nov</div>
          <div class="grid-header">Dec</div>

          <template v-for="(row, rowIndex) in sortedMonthGrid" :key="rowIndex">
            <div class="year-column">{{ row[0] }}</div>
            <div
              v-for="(cell, cellIndex) in row.slice(1)"
              :key="cellIndex"
              :class="['grid-cell', getMonthStatus(row[0], cellIndex + 1, cell).class]"
            >
              <router-link v-if="cell !== 0" :to="`/history/${row[0]}/${cellIndex + 1}`">
                <v-icon small :color="getMonthStatus(row[0], cellIndex + 1, cell).iconColor">
                  {{ getMonthStatus(row[0], cellIndex + 1, cell).icon }}
                </v-icon>
              </router-link>
            </div>
          </template>
        </div>
      </v-card-text>
    </v-card>
  </v-container>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { recordedFetch, API_URL } from '@/services/api';
import { monthStatusService } from '@/services/monthStatus.service';
import { userStore } from '@/stores/user.store';

const monthGrid = ref([]);

const fetchMonthGrid = async () => {
  try {
    const data = await recordedFetch('fetch month grid data', `${API_URL}/find/monthgrid`);
    monthGrid.value = data.map(row => row.slice(0, 13));
  } catch (error) {
    console.error(error);
  }
};

const sortedMonthGrid = computed(() => {
  return [...monthGrid.value].sort((a, b) => b[0] - a[0]);
});

const getMonthStatus = (year, month, photoCount) => {
  const yyyymm = `${year}${String(month).padStart(2, '0')}`;
  const initials = monthStatusService.getInitialsForMonth(yyyymm);
  const isSignedOffByCurrentUser = userStore.initial && initials.includes(userStore.initial);

  let icon = '';
  let iconColor = '';
  let className = '';

  if (photoCount > 0) {
    if (initials.length === 0) {
      icon = 'mdi-emoticon-sad';
      iconColor = 'red';
      className = 'not-signed-off';
    } else if (initials.length === 1) {
      icon = 'mdi-emoticon-neutral';
      iconColor = 'orange';
      className = 'signed-off-by-others';
    } else {
      icon = 'mdi-emoticon-happy';
      iconColor = 'green';
      className = 'signed-off-by-others';
    }

    if (isSignedOffByCurrentUser) {
      className = 'signed-off-by-me';
    }
  }

  return { icon, iconColor, class: className, initials };
};

onMounted(async () => {
  await fetchMonthGrid();
  monthStatusService.fetchMonthlyStatus();
});
</script>

<style scoped>
.month-grid {
  display: grid;
  grid-template-columns: 60px repeat(12, 1fr);
  gap: 2px;
}

.grid-header, .grid-cell {
  text-align: center;
  padding: 4px;
}

.grid-header {
  font-weight: bold;
}

.year-column {
  font-weight: bold;
}

.signed-off-by-me {
  background-color: #e8f5e9; /* Light green */
}
.signed-off-by-others {
  background-color: #fffde7; /* Light yellow */
}
.not-signed-off {
  background-color: #ffebee; /* Light red */
}

@media (max-width: 600px) {
  .month-grid {
    grid-template-columns: 40px repeat(12, 1fr);
    gap: 1px;
  }
  .grid-header, .grid-cell {
    padding: 2px;
    font-size: 0.8em;
  }
}
</style>
