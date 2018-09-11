/**
* Created by Chris on 20/09/2017.
*/
<template>
    <span class="dataService"></span>

</template>

<script>

//    var aupServer = new axios({baseURL:'/api/'})
  export default {
    props: {
      'aurl': {type:String, required:true},
      'params': '',
      'ondemand': {type:Boolean,default: false}
    },
    methods: {
      'loadData' : function() {
        console.log('data-service:loadData='+this.ondemand);
        let self = this;
        if (!this.ondemand)
        this.$http.get('http://localhost:3333/api/'+this.aurl)
          .then(function (response) {
            self.$emit('response',response);
          })
          .catch(function (error) {
            self.$emit('error',error);
          });
      },  // loadData
      'postData' : function(item) {
        console.log('data-service:postData='+this.ondemand);
        console.log(JSON.stringify(item))
        let self = this;
        if (!this.ondemand)
          this.$http.post('http://localhost:3333/api/'+this.aurl,item)
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
        this.loadData()
      },
      params: function (val) {
        this.loadData()
      }
    },

    mounted: function() { this.loadData()}
  }
</script>
