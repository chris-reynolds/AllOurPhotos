<template>
    <!-- Photo grid -->
    <div class="w3-row w3-grayscale-min">
        <div class="w3-quarter">
            <photo-cell filename="images/20170803_164931.jpg"  caption="Pete's kitchen wiring before changes"/>
            <photo-cell filename="images/20170802_142832.jpg"  caption="Wall that needs consent"/>
            <photo-cell filename="images/20170807_073440.jpg"  caption="A gap in the trees"/>
        </div>

        <div class="w3-quarter">
            <photo-cell filename="images/20170807_074726.jpg"  caption="The fourteenth"/>
            <photo-cell filename="images/20170807_075325.jpg"  caption="Beach reflections while golfing"/>
            <photo-cell filename="images/20170807_083700.jpg"  caption="Omokoroa Harbour again"/>
        </div>

        <div class="w3-quarter">
            <photo-cell filename="images/20170807_075028.jpg"  caption="Herons on the tee"/>
            <photo-cell filename="images/20170807_075031.jpg"  caption="A heron on the tee"/>
            <photo-cell filename="images/20170803_164920.jpg"  caption="More wiring"/>
        </div>

        <div class="w3-quarter">
            <photo-cell filename="images/20170807_075328.jpg"  caption="Surrounded by beautiful nature"/>
            <photo-cell filename="images/20170807_084806.jpg"  caption="Too dark to see"/>
            <!--img filename="images/20170808_085252.jpg"  caption="Quiet day at the beach. Cold, but beautiful" -->
            <photo-cell filename="images/20170808_085252.jpg"   caption="Quiet day at the beach. Cold, but beautiful"  />
        </div>
        <paginator></paginator>
    </div>

</template>

<script>
  import PhotoCell from './PhotoCell.vue';
  import Paginator from './Paginator.vue';

  export default {
    props: {

    },
    computed: {

    },
    methods: {

    },
    components: {
      PhotoCell,Paginator
    }
  }
</script>

<style scoped>

</style>