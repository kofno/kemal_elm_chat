/* jshint esnext: true */

document.addEventListener('DOMContentLoaded', () => {
  const elmNode = document.getElementById('app');
  Elm.Main.embed(elmNode, { locationHost: location.host });
});
