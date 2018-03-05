<template>
  <div class="container">
    <my-header sitename="All our photos-6" @open-menu="this.isMenuOpen=true" @close-menu="this.isMenuOpen=false"></my-header>

<p></p>
    <!--p></p>
    <ul>
      <li>
        <v-link href="/">Home</v-link>
        <v-link href="/about">About</v-link>
        <v-link href="/albums">Albums</v-link>
        <v-link href="/about">About</v-link>
      </li>
    </ul-->

    <slot></slot>

    <div>After the slot</div>
    <MyFooter></MyFooter>
    <div class="w3-black w3-center w3-padding-8">Powered by <a href="https://www.w3schools.com/w3css/default.asp" title="W3.CSS" target="_blank" class="w3-hover-opacity">w3.css</a></div>

    <!-- End page content -->
  </div>
</template>

<script>
  import VLink from '../components/VLink.vue'
  import MyFooter from '../components/MyFooter.vue'
  import MyHeader from '../components/MyHeader.vue'

  export default {
    data : function() {
      return {
        isMenuOpen: {type: Boolean}
      }
    },
    components: {
      VLink,MyFooter,MyHeader
    }
  }
</script>

<style scoped>
  .container {
    margin: 0 auto;
    padding: 15px 30px;
    background: #f9f7f5;
  }
</style>
