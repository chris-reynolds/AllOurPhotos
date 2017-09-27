/**
* Created by Chris on 16/09/2017.
*/
<template>
    <main-layout>
        <data-service aurl="years" :params="trigger" @response="gotYears" @error="alert('error')" />
    <div v-if="currentYear==0" class="w3-row w3-grayscale-min" v-for="yearRow in yeargrid">
        <div class="w3-quarter" v-for="yearno in yearRow">
            <div class="yearcell" @click="selectYear(yearno)">
                <span>{{yearno}}</span>
            </div>
        </div>
    </div>
        <div v-if="currentYear" >
            <h1 @click="currentYear=0">{{currentYear}}</h1>
            <div class="monthtab">
                <button :class="isActive(idx)" @click="selectMonth(idx)" v-for="(month,idx) in months">
                  {{month}}</button>
            </div>

            <div class="tabcontent">
                <p>Photos for {{currentYear}}-{{currentMonth}}.</p>
                <photo-grid :photo-list="photoList"></photo-grid>
            </div>

        </div>
    </main-layout>
</template>

<script>
    import _ from 'lodash'
    import MainLayout from '../layouts/Main.vue'
    import DataService from '../components/DataService.vue';
    import PhotoGrid from '../components/PhotoGrid.vue'

  export default {
    props: {},
    data: () => {
      let yearList = [[],[],[],[],[],[],[]];
      for (let i=2017;i>1998;i--) yearList[Math.floor((2017-i) /4) ].push(i);

      return {
        yeargrid : yearList,
        yeargrid2 : [],
        trigger : 0,
        yearsURL : '',
        currentYear : 0,
        currentMonth : '',
        photoList : [],
        months : 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'.split(','),
      }
    }, // data
    computed: {},
    created: function() {
      this.trigger = 1
      console.log('calendar created' +this.yearsURL)
      this.yearsURL = 'xyears'
    },
    methods: {
      gotYears(remoteYears) {
         this.yeargrid = [[],[],[],[],[],[],[]];
        remoteYears = remoteYears.data.reverse();
        for (let i=0;i<remoteYears.length; i++)
          this.yeargrid[Math.floor((i) /4) ].push(remoteYears[i].year);
        console.log('year grid '+JSON.stringify(remoteYears))
      },
      selectYear : function(selectedYearNo) {
        console.log(selectedYearNo+' selected');
        this.currentYear = selectedYearNo;
      },
      selectMonth: function(selectedMonthNo) {
        let self = this;
        this.currentMonth = selectedMonthNo
        this.$http.get('api/month/'+this.currentYear+'/'+(this.currentMonth+1))
          .then(function (response) {
            console.log('responding to month fetch')
            self.photoList = response.data
            console.log('photo count is '+self.photoList.length)
          })
          .catch(function (error) {
            console.log('error on moth fetch '+error)
            self.$emit('error',error);
          });
      },
      isActive :function(monthNo) {
        return (monthNo==this.currentMonth)?'active' : '';
      },
      openMonth : function (evt, directoryName) {

      // Get all elements with class="tabcontent" and hide them
      let tabcontent = document.getElementsByClassName("tabcontent");
      for (let i = 0; i < tabcontent.length; i++) {
        tabcontent[i].style.display = "none";
      }

      // Get all elements with class="tablinks" and remove the class "active"
      let tablinks = document.getElementsByClassName("tablinks");
      for (let i = 0; i < tablinks.length; i++) {
        tablinks[i].className = tablinks[i].className.replace(" active", "");
      }

      // Show the current tab, and add an "active" class to the button that opened the tab
      document.getElementById(cityName).style.display = "block";
      evt.currentTarget.className += " active";
    }
    },  // of methods
    watch: {
      yearsURL : function(val) {
        console.log('yearsURL changed to '+val)
      }
    },
    components: {
      MainLayout, DataService, PhotoGrid
    }
  }
</script>

<style scoped>
    .yearcell {
        height : 5rem;
        padding: 1px;
        border : solid 1px black;
        vertical-align: middle;
        margin-left: auto;
        margin-right: auto;
    }
    .yearcell span {
        font-size : xx-large;
        width:100%;
        margin :50px;
    }
    .yearcell:hover{background-color: antiquewhite; transition: 0.3s}
    /* Style the tab */
    div.monthtab {
        overflow: hidden;
        border: 1px solid #ccc;
        background-color: #f1f1f1;
    }

    /* Style the buttons inside the tab */
    div.monthtab button {
        background-color: inherit;
        float: left;
        border: none;
        outline: none;
        cursor: pointer;
        padding: 14px 16px;
        transition: 0.3s;
    }

    /* Change background color of buttons on hover */
    div.monthtab button:hover {
        background-color: #ddd;
    }

    /* Create an active/current tablink class */
    div.monthtab button.active {
        background-color: #ccc;
    }

    /* Style the tab content */
    .monthtabtabcontent {
        display: none;
        padding: 6px 12px;
        border: 1px solid #ccc;
        border-top: none;
    }
</style>