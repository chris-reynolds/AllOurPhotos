<template>
  <v-container>
    <v-card>
      <v-card-title class="text-h5">Photo History by Month</v-card-title>
      <v-card-text>
        <v-table dense>
          <thead>
            <tr>
              <th>Year</th>
              <th>Jan</th>
              <th>Feb</th>
              <th>Mar</th>
              <th>Apr</th>
              <th>May</th>
              <th>Jun</th>
              <th>Jul</th>
              <th>Aug</th>
              <th>Sep</th>
              <th>Oct</th>
              <th>Nov</th>
              <th>Dec</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(row, rowIndex) in sortedMonthGrid" :key="rowIndex">
              <td>{{ row[0] }}</td>
              <td
                v-for="(cell, cellIndex) in row.slice(1)"
                :key="cellIndex"
                :class="getMonthStatus(row[0], cellIndex + 1, cell).class"
              >
                <router-link v-if="cell !== 0" :to="`/history/${row[0]}/${cellIndex + 1}`">
                  {{ cell }}
                  <span class="ml-1 text-caption">({{ getInitials(row[0], cellIndex + 1) }})</span>
                  <v-icon small :color="getMonthStatus(row[0], cellIndex + 1, cell).iconColor">
                    {{ getMonthStatus(row[0], cellIndex + 1, cell).icon }}
                  </v-icon>
                </router-link>
                <template v-else>
                  {{ cell }}
                </template>
              </td>
            </tr>
          </tbody>
        </v-table>
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
    // Remove the last column (row total) and store the rest
    monthGrid.value = data.map(row => row.slice(0, 13));
  } catch (error) {
    console.error(error);
  }
};

const sortedMonthGrid = computed(() => {
  return [...monthGrid.value].sort((a, b) => b[0] - a[0]);
});

const getInitials = (year, month) => {
  const yyyymm = `${year}${String(month).padStart(2, '0')}`;
  return monthStatusService.getInitialsForMonth(yyyymm);
};

const getMonthStatus = (year, month, photoCount) => {
  const yyyymm = `${year}${String(month).padStart(2, '0')}`;
  const initials = monthStatusService.getInitialsForMonth(yyyymm);
  const isSignedOffByCurrentUser = userStore.initial && initials.includes(userStore.initial);

  let icon = '';
  let iconColor = '';
  let className = '';

  if (photoCount === 0) {
    className = 'no-photos';
  } else {
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

  return { icon, iconColor, class: className };
};

onMounted(async () => {
  await fetchMonthGrid();
  monthStatusService.fetchMonthlyStatus();
});

// watch(
//   () => monthStatusService.monthlyStatus, // Watch for changes in the reactive map
//   () => {},
//   { deep: true } // Deep watch for changes within the map
// );
</script>

<style scoped>
.signed-off-by-me {
  background-color: #e8f5e9; /* Light green */
}
.signed-off-by-others {
  background-color: #fffde7; /* Light yellow */
}
.not-signed-off {
  background-color: #ffebee; /* Light red */
}

</style>