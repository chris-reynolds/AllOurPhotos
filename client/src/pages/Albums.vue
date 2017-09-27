<template>
    <main-layout>
        <h1 @click="currentAlbum=''">Albums</h1>
        <div id="albumSelection" v-if="!currentAlbum">
            <ul>
              <li class="albumhover" v-for="album in albums" @click="currentAlbum=album">{{album.title}}</li>
            </ul>

        </div>
        xxxx
        <div id="currentAlbumSelection" v-if="currentAlbum">
            <h1  @click="currentAlbum=''">{{currentAlbum.title}}</h1>
            <photo-grid :photo-list="currentAlbum.photos"></photo-grid>
        </div>
        yyyy
    </main-layout>
</template>

<script>
  import MainLayout from '../layouts/Main.vue'
  import datasource from '../fixtures'
  import PhotoGrid from '../components/PhotoGrid.vue'

  export default {
    data : function()  {
      return {
      albums : datasource.Albums.reverse(),
      currentAlbum : ''
    }
    }, // of data
    methods : {

    }, // of methods
    components: {
      MainLayout, PhotoGrid
    }
  }
</script>

<style>
    .albumhover:hover {
        color:red;
    }
</style>
