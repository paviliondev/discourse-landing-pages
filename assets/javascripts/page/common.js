var $contactForm = $("#contact-form");

if ($contactForm.length) {
  var $contactSubmit = $contactForm.find('.btn-primary');
  
  $contactForm.find('input, textarea').on("keydown", function(e) {
    if (e.keyCode == 13 && e.shiftKey) {
      $contactForm.submit();
    }
  });

  $contactForm.on("ajax:send", function() {
    $contactForm.addClass('submitting');
    $contactSubmit.attr("disabled", true);
  });

  $contactForm.on("ajax:success", function() {
    $contactForm.removeClass('submitting');
    $contactForm.addClass('submitted');
    $contactForm.find('input, textarea').val('');
    $contactSubmit.attr("disabled", false);
    setTimeout(function() { $contactForm.removeClass('submitted'); }, 10000);
  });
}

var $window = $(window);
var $body = $("body");

$window.on("scroll", function() {
  $body.toggleClass('scrolled', $window.scrollTop() > 0);
});
