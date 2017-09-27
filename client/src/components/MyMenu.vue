<template>
    <nav class="w3-sidebar w3-bar-block w3-black w3-animate-right w3-top w3-text-light-grey w3-large" style="z-index:3;width:250px;font-weight:bold;right:0;" id="mySidebar">
        <v-link href="#Home" @click="w3_close()" >Home</v-link>
        <v-link href="#Albums" @click="w3_close()" >Albums</v-link>
        <v-link href="#Calendar" @click="w3_close()" >Calendar</v-link>
    </nav>
</template>

<script>
  import routes from '../routes';
  import VLink from './VLink.vue';

  export default {
    props: [],

    computed: {

    },
    methods: {
      w3_close :function() {
        console.log('MyMenu.w3close');
        this.$emit('closemenu');
      }

    },
    components: {
      VLink
    }
  }
</script>

<style scoped>

</style>