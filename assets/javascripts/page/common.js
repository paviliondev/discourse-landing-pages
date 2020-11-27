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
});

function applyFixedStyle(element) {
  element.style.position = 'fixed';
  element.style.top = "300px";
  element.style['justify-content'] = "center";
  element.style['animation-iteration-count'] = 1;
  element.style.animation = "shake 1s ease-in-out";
}

function applyAbsoluteStyle(element) {
  element.style.position = 'absolute';
  element.style['justify-content'] = "flex-start";
  element.style.top = "0";
}

var $we = $("#we");
var state = 'absolute';

$('.we-anchor, .page').each(function() {
  var $this = $(this);
  var element = $this[0];
  var page = $this.data("page");
  var $anchor = $(`.we-anchor[data-page=${page}]`);
    
  var waypoint = new Waypoint({
    element,
    handler: function(direction) {
      console.log(direction, state)
      if (state == 'fixed') {
        state = 'absolute';
        $we.animate({
          top: $anchor.scrollTop
        }, function() {
          $we.appendTo($anchor);
          applyAbsoluteStyle($we[0]);
        });
      } else {
        state = 'fixed';
        applyFixedStyle($we[0]);
      }
    },
    offset: 0
  });
});
