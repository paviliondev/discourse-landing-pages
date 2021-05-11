var $forms = $(".contact-form, .subscription-form");

if ($forms.length) {
  $forms.each(function() {
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

        $form.find('input[type=text], textarea').val('');
        $submit.attr("disabled", false);

        setTimeout(function() {
          $form.removeClass('submitted');
          $form.removeClass('success');
          $form.removeClass('error');
        }, 10000);
      });

      return false;
    });
  });
}

var $window = $(window);
var $body = $("body");
var $document = $(document);
var $footer = $('footer');
var $topicLists = $('.topic-list[data-scrolling-topic-list="true"]');

function loadTopics($topicList) {
  let topicListBottom = $topicList.offset().top + $topicList.outerHeight(true);
  let windowBottom = $window.scrollTop() + $window.height();
  let reachedBottom = topicListBottom <= (windowBottom - 50);
  let loading = $topicList.hasClass('loading');

  if (reachedBottom && !loading) {
    const count = $topicList.children().length;
    const perPage = Number($topicList.data('list-per-page'));
    const page = Number($topicList.data('list-page'));
    const data = {
      page_id: $topicList.data('page-id'),
      list_opts: {
        category: $topicList.data('list-category'),
        page,
        per_page: perPage,
        no_definitions: $topicList.data('list-no-definitions')
      },
      item_opts: {
        classes: $topicList.data('item-classes'),
        excerpt_length: $topicList.data('item-excerpt-length'),
        include_avatar: $topicList.data('item-include-avatar'),
        avatar_size: $topicList.data('item-avatar-size')
      }
    }

    if (count >= (perPage * (page + 1)) {
      $topicList.addClass('loading');

      $.ajax({
        type: "GET",
        url: '/landing/topic-list',
        data,
        success: function(result) {
          $topicList.append(result.topics_html);
          $topicList.data('page', data.page + 1);
        }
      }).always(function() {
        $topicList.removeClass('loading');
      });
    }
  }
}

$window.on("scroll", function() {
  $body.toggleClass('scrolled', $window.scrollTop() > 0);

  if ($topicLists.length) {
    $topicLists.each(function() {
      loadTopics($(this));
    });
  }
});
