<template>
        <!-- Modal for full size images on click-->
        <div id="modal01" class="w3-black" style="padding-top:0" @click="closeme()">
            <span class="w3-button w3-black w3-xlarge w3-display-topright">&times;</span>
            <div class="w3-animate-zoom w3-center w3-transparent w3-padding-64">
                <img id="img01" :src="filename()" class="w3-image">
                <p id="caption">{{picture.caption}}</p>
            </div>
        </div>
</template>

<script>
//  import routes from '../routes'

  export default {
    props: [
      'picture'
    ],
    computed: {

    },
    methods: {
      closeme : function() {
        this.$emit('close');
      },
      filename : function() {
         console.log('looking at "'+this.picture.filename+'"');
         return this.picture.filename;
      } ,

    }
  }
</script>

<style scoped>

</style>