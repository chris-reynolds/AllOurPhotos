<template>
    <div>
  <my-menu @closemenu="w3_close()" v-if="menuIsOpen" >

  </my-menu>
        <!-- Overlay effect when opening sidebar on small screens -->
        <div v-if="menuIsOpen" class="w3-overlay w3-animate-opacity" @click="w3_close()" style="cursor:pointer;display:block"
             title="close menu" id="myOverlay"></div>
    <!-- Top menu on small screens -->
    <header class="w3-container w3-top w3-white w3-xlarge w3-padding-16">
        <span class="w3-left w3-padding">{{sitename}}</span>
        <a href="javascript:void(0)" class="w3-right w3-button w3-white" @click="w3_open()">&#9776;</a>
    </header>
    </div>
</template>

<script>
  import MyMenu from './MyMenu.vue'

  export default {
    props: [
      'sitename'
    ],
    computed: {

    },
    data: function () {
      return {
        menuIsOpen : false
      };
    },
    methods: {
      w3_close : function() {
        console.log('myheader.w3close1');
        this.menuIsOpen = false;
        this.$emit('close_menu');
      },
      w3_open : function() {
        console.log('myheader.w3open1');
        this.menuIsOpen = true;
        this.$emit('open-menu');
      }

    },
    components: {
      MyMenu
    }
  }
</script>

<style scoped>

</style>