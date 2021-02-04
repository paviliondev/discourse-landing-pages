var $contactForm = $(".contact-form");

if ($contactForm.length) {
  $contactForm.each(function() {
    var $form = $(this);
    var $submit = $(this).find('.btn-primary');
    
    $form.find('input, textarea').on("keydown", function(e) {
      if (e.keyCode == 13 && e.shiftKey) {
        $form.submit();
      }
    });
    
    console.log($form);
    
    $form.submit(function() {
      $form.addClass('submitting');
      $submit.attr("disabled", true);
       
      $.ajax({
        type: "POST",
        url: $(this).attr('action'),
        data: $(this).serialize(),
        dataType: "JSON",
      }).always(function(result) {
        console.log(result)
        if (result && result.status == 200) {
          $form.addClass('success');
        } else {
          $form.addClass('error');
        }
        $form.removeClass('submitting');
        $form.addClass('submitted');
        
        $form.find('input, textarea').val('');
        $submit.attr("disabled", false);
        
        setTimeout(function() {
          $form.removeClass('submitted');
          $form.removeClass('success');
          $form.removeClass('error');
        }, 5000);
      });
      
      return false;
    });
  });
}

var $window = $(window);
var $body = $("body");

$window.on("scroll", function() {
  $body.toggleClass('scrolled', $window.scrollTop() > 0);
});
