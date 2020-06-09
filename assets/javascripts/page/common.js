var $form = $("#contact-form");

if ($form.length) {
  var $submit = $form.find('.btn-primary');

  $form.on("ajax:send", function() {
    $submit.addClass('submitting');
    $submit.attr("disabled", true);
  });

  $form.on("ajax:success", function() {
    $submit.removeClass('submitting');
    $submit.addClass('submitted');
    $submit.attr("disabled", false);
    setTimeout(function() { $submit.removeClass('submitted'); }, 7000);
  });
}

$(window).on("scroll", function() {
  $("body").toggleClass('scrolled', $(window).scrollTop() > 0);
});