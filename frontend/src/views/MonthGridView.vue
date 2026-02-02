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
            <div class="year-column">{{ row['year(`taken_date`)'] }}</div>
            <div
              v-for="(month, monthIndex) in months"
              :key="monthIndex"
              :class="['grid-cell', getMonthStatus(row['year(`taken_date`)'], monthIndex + 1, row[month]).class]"
            >
              <router-link v-if="row[month] !== '0'" :to="`/history/${row['year(`taken_date`)']}/${monthIndex + 1}`">
                <v-icon size="small" :color="getMonthStatus(row['year(`taken_date`)'], monthIndex + 1, row[month]).iconColor">
                  {{ getMonthStatus(row['year(`taken_date`)'], monthIndex + 1, row[month]).icon }}
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
import { ref, onMounted, computed } from 'vue'
import { api } from '@/services/api'
import { monthStatusService } from '@/services/monthStatus.service'
import { useAuthStore } from '@/stores/auth'
import { logger } from '@/utils/logger'

const authStore = useAuthStore()
const monthGrid = ref([])
const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

const fetchMonthGrid = async () => {
  try {
    logger.info('Fetching month grid', null, 'MONTH_GRID')
    const data = await api.get('/find/monthgrid')
    monthGrid.value = data
    logger.info(`Fetched ${data.length} years of data`, null, 'MONTH_GRID')
  } catch (error) {
    logger.error('Failed to fetch month grid', error, 'MONTH_GRID')
  }
}

const sortedMonthGrid = computed(() => {
  return [...monthGrid.value].sort((a, b) => b['year(`taken_date`)'] - a['year(`taken_date`)'])
})

const getMonthStatus = (year, month, photoCount) => {
  const yyyymm = `${year}${String(month).padStart(2, '0')}`
  const initials = monthStatusService.getInitialsForMonth(yyyymm)
  const isSignedOffByCurrentUser = authStore.userInitial && initials.includes(authStore.userInitial)

  let icon = ''
  let iconColor = ''
  let className = ''

  const count = parseInt(photoCount) || 0

  if (count > 0) {
    if (initials.length === 0) {
      icon = 'mdi-emoticon-sad'
      iconColor = 'red'
      className = 'not-signed-off'
    } else if (initials.length === 1) {
      icon = 'mdi-emoticon-neutral'
      iconColor = 'orange'
      className = 'signed-off-by-others'
    } else {
      icon = 'mdi-emoticon-happy'
      iconColor = 'green'
      className = 'signed-off-by-others'
    }

    if (isSignedOffByCurrentUser) {
      className = 'signed-off-by-me'
    }
  }

  return { icon, iconColor, class: className, initials }
}

onMounted(async () => {
  await fetchMonthGrid()
  monthStatusService.fetchMonthlyStatus()
})
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
