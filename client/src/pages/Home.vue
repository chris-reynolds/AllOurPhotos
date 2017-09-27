<template>
  <main-layout>
    <p>Welcome home</p>
    <photo-gridxxx></photo-gridxxx>

  </main-layout>
</template>

<script>
  import MainLayout from '../layouts/Main.vue'
  import PhotoGridxxx from '../components/PhotoGridxxx.vue';

  export default {
    components: {
      MainLayout, PhotoGridxxx
    }
  }
</script>
