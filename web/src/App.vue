<template>
  <div>
    <PicGen />
  </div>
</template>

<script>
import PicGen from "./components/PicGen";

export default {
  name: "PicGenApp",
  components: {
    PicGen,
  },
};
</script>

<style>
#app {
  font-family: "Avenir", Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
