<template>
  <v-container>
    <v-toolbar flat>
      <v-toolbar-title>Photos for {{ monthName }} {{ year }}</v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn icon @click="$router.back()">
        <v-icon>mdi-arrow-left</v-icon>
      </v-btn>
      <v-btn color="primary" @click="toggleSignOff(authStore.userInitial)">
        {{ isSignedOffByCurrentUser ? 'Unsign' : 'Sign' }} Off {{ authStore.userInitial ? `(${authStore.userInitial})` : '' }}
      </v-btn>
    </v-toolbar>

    <PhotoGrid :snaps="snaps" :criteria="searchCriteria" />
  </v-container>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue'
import { useRoute } from 'vue-router'
import PhotoGrid from '@/components/PhotoGrid.vue'
import { monthStatusService } from '@/services/monthStatus.service'
import { useAuthStore } from '@/stores/auth'
import { useSnapsStore } from '@/stores/snaps'
import { useUIStore } from '@/stores/ui'
import { logger } from '@/utils/logger'

const route = useRoute()
const authStore = useAuthStore()
const snapsStore = useSnapsStore()
const uiStore = useUIStore()

const snaps = ref([])
const searchCriteria = ref({})
const year = ref(null)
const month = ref(null)

const monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
]

const monthName = computed(() => {
  return month.value ? monthNames[month.value - 1] : ''
})

const isSignedOffByCurrentUser = computed(() => {
  if (!authStore.userInitial) return false
  const yyyymm = `${year.value}${String(month.value).padStart(2, '0')}`
  const initials = monthStatusService.getInitialsForMonth(yyyymm)
  return initials.includes(authStore.userInitial)
})

const fetchMonthSnaps = async (thisYear, thisMonth) => {
  try {
    logger.info('Fetching month snaps', { year: thisYear, month: thisMonth }, 'MONTH_DETAILS')

    const startDate = new Date(thisYear, thisMonth - 1, 1)
    const endDate = new Date(thisYear, thisMonth, 1) // First day of next month
    month.value = thisMonth
    year.value = thisYear
    searchCriteria.value = {
      startdate: startDate,
      enddate: endDate,
      ranking: '2,3',
      orderby: 'taken_date'
    }

    snapsStore.setFilter(searchCriteria.value)
    const data = await snapsStore.fetchSnaps(
      `taken_date >= '${startDate.toISOString()}' AND taken_date < '${endDate.toISOString()}' AND ranking IN (2,3)`,
      'taken_date'
    )
    snaps.value = data
  } catch (error) {
    logger.error('Failed to fetch month snaps', error, 'MONTH_DETAILS')
  }
}

const toggleSignOff = async (initial) => {
  if (!initial) {
    uiStore.showWarning('User initial not available for sign-off')
    return
  }

  try {
    const yyyymm = `${year.value}${String(month.value).padStart(2, '0')}`
    const currentInitials = monthStatusService.getInitialsForMonth(yyyymm)
    const signedOff = currentInitials.includes(initial)
    await monthStatusService.toggleSignOff(yyyymm, initial, !signedOff)
    uiStore.showSuccess(`Successfully ${signedOff ? 'unsigned' : 'signed'} off ${monthName.value}`)
  } catch (error) {
    uiStore.showError('Failed to update sign-off status')
  }
}

onMounted(async () => {
  year.value = parseInt(route.params.year)
  month.value = parseInt(route.params.month)
  await fetchMonthSnaps(year.value, month.value)
  monthStatusService.fetchMonthlyStatus()
})

watch(
  () => route.params,
  async (newParams) => {
    year.value = parseInt(newParams.year)
    month.value = parseInt(newParams.month)
    await fetchMonthSnaps(year.value, month.value)
    monthStatusService.fetchMonthlyStatus()
  }
)
</script>
