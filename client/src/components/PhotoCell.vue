<template>
    <div class="photocell autoexpand">
    <img class="rotateimg270x" :src="thumbnailURL()" style="width:100%" @click="photoClick(this)" :alt="caption"/>
        <my-editor :filename="filename" :caption="caption" />
    </div>
</template>

<script>
  import MyEditor from './MyEditor.vue'

  export default {
    props: [
      'filename','caption'
    ],
    computed: {

    },
    methods: {
      photoClick : function(event) {
        console.log('emits '+this.filename)
        this.$emit('selectphoto');
        console.log('emitted2 '+this.filename)
      }, // of event
      thumbnailURL : function() {
        let segments = this.filename.split('/')
        segments.splice(segments.length-1,0,'thumbnails')
        return segments.join('/');
      }
    },
    components : {MyEditor}
  }
</script>

<style scoped>
.photocell {
    width: 100%;
    padding: 5px;
}
.autoexpand {
    overflow: auto;
}
.rotateimg90 {
    -webkit-transform:rotate(90deg);
    -moz-transform: rotate(90deg);
    -ms-transform: rotate(90deg);
    -o-transform: rotate(90deg);
    transform: rotate(90deg);
}
.rotateimg180 {
    -webkit-transform:rotate(180deg);
    -moz-transform: rotate(180deg);
    -ms-transform: rotate(180deg);
    -o-transform: rotate(180deg);
    transform: rotate(180deg);
}
.rotateimg270 {
    -webkit-transform:rotate(270deg);
    -moz-transform: rotate(270deg);
    -ms-transform: rotate(270deg);
    -o-transform: rotate(270deg);
    transform: rotate(270deg);
}
</style>