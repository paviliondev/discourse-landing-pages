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

$(window).on("scroll", function() {
  $("body").toggleClass('scrolled', $(window).scrollTop() > 0);
});

var $waypointList = $('ul.waypoint-list');

if ($waypointList.length) {
  $waypointList.children().each(function() {
    var $item = $(this);
    var $anchor = $item.find('a');
    var id = $anchor.attr('href');
    var $id = $(id);

    if ($id.length) {
      new Waypoint({
        element: document.getElementById(id.substr(1)),
        handler: function(direction) {
          $waypointList.find('a').removeClass('active');
          
          if (direction == 'down') {
            $anchor.addClass('active');
          } else {
            $item.prev().find('a').addClass('active');
          }
        },
        offset: '50%' 
      });
      
      $anchor.on('click', function(e) {
        e.preventDefault();
        
        $('html, body').animate({
          scrollTop: $id.offset().top - 130
        }, 400, function() {
          history.pushState({}, '', id);
        });
      })
    }
  });
}

$("a.scroll-and-center").on('click', function(e) {
  e.preventDefault();
  
  var el = $(e.target.getAttribute('href'));
  var elOffset = el.offset().top;
  var elHeight = el.height();
  var windowHeight = $(window).height();
  var offset;

  if (elHeight < windowHeight) {
    offset = elOffset - ((windowHeight / 2) - (elHeight / 2));
  } else {
    offset = elOffset;
  }

  $('html, body').animate({
    scrollTop: offset
  }, 400);
})