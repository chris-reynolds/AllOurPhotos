<template>
    <!-- Photo grid -->
    <div  v-if="this.isGridShowing">
        <div class="w3-row w3-grayscale-min"v-for="pictureRow in pictureRows" >
            <div class="w3-half" v-for="picture in pictureRow" :key="picture.filename">
            <photo-cell @selectphoto="selectPhoto(picture)" :picture="picture" :prefix="prefix" />
            </div>
        </div>
        <div @click="resetSelection()" v-if="!this.isGridShowing">Back</div>
      <div style="border: red 5px solid">
        <modal-picture :picture="this.selectedPicture"
                       v-if="this.selectedPicture.filename" @close="resetSelection()" />
      </div>
        <paginator ></paginator>
    </div>

</template>


<script>
    import PhotoCell from './PhotoCell.vue';
    import Paginator from './Paginator.vue';
    import ModalPicture from './ModalPicture.vue';

  export default {
    props: ['photoList','prefix'],
    data : function() {
      return {
        isGridShowing : true,
        selectedPicture : {filename:'',caption:''}};
    },
    computed: {
      pictureRows : function() {
        if (this.photoList && this.photoList.length>0){
          let rowLength = 4;
          let arrLength = Math.floor((this.photoList.length-1)/4)+1
          let resultRows = new Array(arrLength);
          for (let i=0; i<resultRows.length; i++) resultRows[i]=[];
          for (let i=0; i<this.photoList.length; i++) {
            console.log('picture '+i+' '+this.photoList[i].filename)
            resultRows[Math.floor(i / 4)].push(this.photoList[i]);
          }
          return resultRows;
        } else
          return [];
      } // of pictureRows
    },
    methods: {
      resetSelection() {
        this.isGridShowing = true;
        this.selectedPicture = {filename:'',caption:''}

      },
      selectPhoto(picture) {
          console.log('made it to photogrid method');
          this.selectedPicture = picture;
          this.isGridShowing = false;
        }
    },
    components: {
      PhotoCell,Paginator,ModalPicture
    },
    watch: {
      photoList : function() {
        this.resetSelection()
        console.log('reset selection based on watching photolist')
      }
    }
  }
</script>

<style scoped>

</style>