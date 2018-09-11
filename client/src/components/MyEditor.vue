/**
* Created by Chris on 23/09/2017.
*/
<template>
    <div class="myEditor" >
      <data-service id="dsPicturePost" aurl="picture/post" :params="picture" ondemand='true' @response="postedPicture" @error="showError"/>
        <div  >
            <icon style="color:red" name="pencil" @click.native="toggleEdit" />
            <span v-if="!editMode"> {{picture.caption}}  O{{picture.orientation}}</span>
            <div v-if="editMode" class="group" style="">
                <icon name="thumbs-up" @click.native="rankEdit(5)" />
                <icon name="minus" @click.native="rankEdit(3)" />
                <icon name="thumbs-down" @click.native="rankEdit(1)" />
                <icon name="rotate-left" @click.native="orientationEdit(-1)" />
                <icon name="rotate-right" @click.native="orientationEdit(1)" />
                <input v-model="picture.caption" style=""  />
            </div>
        </div>

        </div>

</template>

<script>
  import Icon from 'vue-awesome/components/Icon.vue'
  import DataService from './DataService.vue'

  export default {
    props: ['picture'],
    data : function(){
      return {
        editMode:false,
        newPicture:{}
      }
    },
    computed: {},
    methods: {
      toggleEdit : function() {
        console.log('my icon clicked')
        if (this.editMode) {
          console.log('check context here')
        }
        this.editMode=!this.editMode
      },
      rankEdit : function(newRank) {
        console.log('new rank '+newRank)
        this.picture.rank = newRank
      },
      orientationEdit : function(change) {
        this.picture.orientation = (this.picture.orientation + change +4 )%4
        console.log('orientation = '+this.orientation)
      },
      postedPicture: function(response) {
        alert.show('posted ok '+JSON.stringify(response))
      },
      showError:function(response) {
        alsert.show('FAILED POST '+JSON.stringify(response))
      }

    },
    components: {Icon,DataService}
  }
</script>

<style scoped>
    .myEditor {
        width : 100%;
        background-color: yellow;
    }

</style>