document.addEventListener("DOMContentLoaded", function () {
  Object.keys(requirejs.entries).forEach(function (name) {
    requirejs(name, null, null, true);
  });
});
