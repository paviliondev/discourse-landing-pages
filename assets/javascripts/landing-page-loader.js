document.addEventListener("DOMContentLoaded", function(event) { 
  Object.keys(requirejs.entries).forEach(name => {
    requirejs(name, null, null, true)
  });
});