/**
* Created by Chris on 23/09/2017.
*/
<template>
    <div class="myEditor" >
        <div v-if="!editMode" >
            <icon style="color:red" name="pencil" @click.native="toggleEdit" />
            <span> {{caption}}</span>
        </div>
        <div v-if="editMode" >
            <div style="">
                <icon style="color:red" name="pencil" @click.native="toggleEdit" />
            <div class="group" style="">
                <icon name="thumbs-up" @click.native="rankEdit(5)" />
                <icon name="minus" @click.native="rankEdit(3)" />
                <icon name="thumbs-down" @click.native="rankEdit(1)" />
            </div>
            <div class="group" style="">
                <icon name="rotate-left" @click.native="orientationEdit(-1)" />
                <icon name="rotate-right" @click.native="orientationEdit(1)" />
            </div>
            </div>
            <textarea :value="caption" style="width:100%; top:20px"  />

        </div>



    </div>

</template>

<script>
  import Icon from 'vue-awesome/components/Icon.vue'

  export default {
    props: ['filename','caption','orientation','rank'],
    data : function(){
      return {editMode:false }
    },
    computed: {},
    methods: {
      toggleEdit : function() {
        console.log('my icon clicked')
        this.editMode=!this.editMode
      },
      rankEdit : function(newRank) {
        console.log('new rank '+newRank)
        this.rank = newRank
      },
      orientationEdit : function(change) {
        this.orientation += change
        console.log('orientation = '+this.orientation)
      }

    },
    components: {Icon}
  }
</script>

<style scoped>
    .myEditor {
        width : 100%;
        background-color: yellow;
    }

</style>