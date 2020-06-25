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

var $waypointList = $('ul.waypoint-list');

if ($waypointList.length) {
  $waypointList.children().each(function() {
    let $item = $(this);
    let $anchor = $item.find('a');
    let id = $anchor.attr('href');
    let $id = $(id);

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
  
  let el = $(e.target.getAttribute('href'));
  let elOffset = el.offset().top;
  let elHeight = el.height();
  let windowHeight = $(window).height();
  let offset;

  if (elHeight < windowHeight) {
    offset = elOffset - ((windowHeight / 2) - (elHeight / 2));
  } else {
    offset = elOffset;
  }

  $('html, body').animate({
    scrollTop: offset
  }, 400);
})