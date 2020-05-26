document.addEventListener("DOMContentLoaded", function(event) { 
  Object.keys(requirejs.entries).forEach(function(name) {
    requirejs(name, null, null, true)
  });
});