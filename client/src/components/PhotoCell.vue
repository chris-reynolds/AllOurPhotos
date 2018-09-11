<template>
    <div class="photocell autoexpand">
    <img :class="orientationClass(picture.orientation)" :src="thumbnailURL()" style="width:100%" @click="photoClick(this)" :alt="picture.caption"/>
        <my-editor :picture="picture" />
      <div style="top: 8px; right: 16px;">a-{{picture.filename}}</div>
    </div>
</template>

<script>
  import MyEditor from './MyEditor.vue'

  export default {
    props: [
      'picture','prefix'
    ],
    computed: {

    },
    methods: {
      photoClick : function(event) {
        console.log('emits '+this.picture.filename)
        this.$emit('selectphoto');
        console.log('emitted2 '+this.picture.filename)
      }, // of event
      thumbnailURL : function() {
        console.log('prefix is '+this.prefix)
        let segments = this.picture.filename.split('/')
        segments.splice(segments.length-1,0,'thumbnails')
        return this.prefix+'/'+segments.join('/');
      },
      orientationClass: function(orientn) {
        switch(orientn) {
          case 6 : return 'rotateimg90'
          case 8 : return 'rotateimg270'
          default:   return 'rotateimg0'
        }
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
  .rotateimg0 {

  }
</style>