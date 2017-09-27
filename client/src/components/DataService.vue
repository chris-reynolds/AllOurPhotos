/**
* Created by Chris on 20/09/2017.
*/
<template>
    <span class="dataService"></span>

</template>

<script>

//    var aupServer = new axios({baseURL:'/api/'})
  export default {
    props: ['aurl','params'],
    computed: {
        datafetch : function(){
          console.log('data-service:datafetch');
          this.$http.get('/api/'+this.aurl,{params:this.params})
          .then(function (response) {
            this.$emit('response',response);
          })
          .catch(function (error) {
            this.$emit('error',error);
          });


        }
    }, // of computed
    methods: {
      'loadData' : function(val) {
        console.log('data-service:loadData='+val);
        let self = this;
        this.$http.get('/api/'+this.aurl)
          .then(function (response) {
            self.$emit('response',response);
          })
          .catch(function (error) {
            self.$emit('error',error);
          });
      }
    },
    watch: {
      aurl: function (val) {
        this.loadData(val)
      },
      params: function (val) {
        this.loadData(val)
      }
    },

    mounted: function() { this.loadData()}
  }
</script>
