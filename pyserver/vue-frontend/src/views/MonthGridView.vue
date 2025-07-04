<template>
  <div>
    <h1>Photo History by Month</h1>
    <table>
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
          <td v-for="(cell, cellIndex) in row" :key="cellIndex">
            <template v-if="cellIndex === 0">{{ cell }}</template>
            <template v-else>{{ cell === 0 ? '' : cell }}</template>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';

const monthGrid = ref([]);

const fetchMonthGrid = async () => {
  try {
    const jam = localStorage.getItem('jam');
    const headers = {
      'Content-Type': 'application/json',
      'Preserve': jam ? jam : ''
    };
    const response = await fetch('http://localhost:8000/find/monthgrid', { headers });
    if (!response.ok) {
      throw new Error('Failed to fetch month grid data');
    }
    const data = await response.json();
    // Remove the last column (row total) and store the rest
    monthGrid.value = data.map(row => row.slice(0, 13));
  } catch (error) {
    console.error(error);
  }
};

const sortedMonthGrid = computed(() => {
  return [...monthGrid.value].sort((a, b) => b[0] - a[0]);
});

onMounted(fetchMonthGrid);
</script>

<style scoped>
table {
  width: 100%;
  border-collapse: collapse;
}

th, td {
  border: 1px solid #ddd;
  padding: 8px;
  text-align: center;
}

th {
  background-color: #f2f2f2;
}
</style>
