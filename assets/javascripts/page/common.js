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
        
    $form.submit(function() {
      $form.addClass('submitting');
      $submit.attr("disabled", true);
       
      $.ajax({
        type: "POST",
        url: $(this).attr('action'),
        data: $(this).serialize(),
        dataType: "JSON",
      }).always(function(result) {
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

function getElementOffset(el) {
  var elOffset = el.offset().top;
  var elHeight = el.height();
  var windowHeight = $(window).height();
  var offset;

  if (elHeight < windowHeight) {
    offset = elOffset - ((windowHeight / 2) - (elHeight / 2));
  } else {
    offset = elOffset;
  }

  return offset;
}

window.addEventListener('DOMContentLoaded', (event) => {
  $("a.scroll-and-center").on('click', function(e) {
    e.preventDefault();
    $('html, body').animate({
      scrollTop: getElementOffset($(e.target.getAttribute('href')))
    }, 400);
  });

  var $memberList = $('#member-list');
  var $toggleList = $memberList.find('.item-list-toggle');
  var $itemList = $memberList.find('.item-list');

  function handleGroupToggle(group) {
    if (group && group !== 'everyone') {
      $itemList.find(`.item:not(.${group})`).removeClass("show");
      $itemList.find(`.item.${group}`).addClass("show");
    } else {
      $itemList.find('.item').addClass('show');
    }
  }

  handleGroupToggle(window.location.hash.replace(/^#/, ''));

  $memberList.find('a.toggle').on("click", function(e) {
    $toggleList.find('.toggle').removeClass('active');
    $(e.target).addClass('active');
    handleGroupToggle(e.target.getAttribute("data-group"));
  });
});
