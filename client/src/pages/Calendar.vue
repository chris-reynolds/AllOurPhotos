/**
* Created by Chris on 16/09/2017.
*/
<template>
    <main-layout>
        <data-service aurl="years" :params="trigger" @response="gotYears" @error="showAlert" />
    <div v-if="currentYear.year==0" class="w3-row w3-grayscale-min" v-for="yearRow in yeargrid">
        <div class="w3-quarter" v-for="yearno in yearRow">
            <div class="yearcell" @click="selectYear(yearno)">
                <span>{{yearno}}</span>
            </div>
        </div>
    </div>
        <div v-if="currentYear.year>0" >
            <div class="monthtab">
              <div @click="currentYear.year=0">{{currentYear.year}}</div>
                <button :class="isActive(idx+1)" v-if="existingMonth(idx+1)"  @click="selectMonth(idx+1)" v-for="(month,idx) in months">
                  {{month}}</button>
            </div>

            <div class="tabcontent">
                <p>Photos for {{months[currentMonth-1]}} {{currentYear.year}}</p>
                <photo-grid :photo-list="photoList" :prefix="urlPrefix"></photo-grid>
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
        remoteYears:[],
        currentYear : {year:0,months:[]},
        currentMonth : '',
        currentDirectory : 'zzzz',
        photoList : [],
        urlPrefix:'',
        months : 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'.split(',')
      }
    }, // data
    computed: {},
    created: function() {
      this.trigger = 1
      console.log('calendar created' +this.yearsURL)
      this.yearsURL = 'xyears'
    },
    methods: {
      existingMonth(monthNo) {
        if (monthNo<10)
          monthNo = '0'+monthNo
        else
          monthNo = ''+monthNo
        return (this.currentYear.months.indexOf(monthNo)>=0)
      },
      gotYears(theseRemoteYears) {
        this.remoteYears = theseRemoteYears.data.reverse();
         this.yeargrid = [[],[],[],[],[],[],[]];
        for (let i=0;i<this.remoteYears.length; i++)
          this.yeargrid[Math.floor((i) /4) ].push(this.remoteYears[i].year);
        console.log('year grid '+JSON.stringify(this.remoteYears))
      },
      selectYear : function(selectedYearNo) {
        console.log(selectedYearNo+' selected.');
  //      this.currentYear = selectedYearNo;
        this.photoList =[]
        this.currentMonth = ''
        for (let yearIx in this.remoteYears) {
          let remoteYear = this.remoteYears[yearIx]
          if (selectedYearNo == remoteYear.year)
            this.currentYear = remoteYear
            }
      },
      selectMonth: function(selectedMonthNo) {
        let self = this;
        this.currentMonth = selectedMonthNo
        this.$http.get('http://localhost:3333/api/month/'+this.currentYear.year+'/'+(this.currentMonth))
          .then(function (response) {
            console.log('responding to month fetch')
            self.currentDirectory = response.data.directory
            self.urlPrefix = 'http://localhost:3333/images/'+self.currentDirectory
            self.photoList = response.data.files
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
      showAlert(message) {
        alert(message)
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