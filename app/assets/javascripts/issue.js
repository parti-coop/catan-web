$(function() {
  $('[data-action="parti-select-interested-tag"]').each(function(index, elm){
    $(this).on('click',function (e){
      if($(this).hasClass('selected-tag')) {
        $(this).removeClass('selected-tag');
      } else {
        $(this).addClass('selected-tag');
      }

      if($('[data-action="parti-select-interested-tag"].selected-tag').length > 0) {
        $('.js-intro-select-parties-cog').addClass('collapse');
        $('.js-intro-select-parties-continue').removeClass('collapse');
      } else {
        $('.js-intro-select-parties-cog').removeClass('collapse');
        $('.js-intro-select-parties-continue').addClass('collapse');
      }
    });
  });

  $('.js-intro-select-parties-continue').each(function(index, elm){
    $(this).on('click',function (e){
      $(e.target).html('추천 중...');
      $(e.target).prop('disabled', true);
      $.ajax({
        url: '/parties/search_by_tags.js',
        type: "get",
        data:{
          selected_tags: $('.selected-tag').text().trim().split(/\s+/),
        },
        complete: function(xhr) {
          $('.parti-member-recommend--select-interest').hide();
          $('#header-before-select-tags').hide();
          $('#header-after-select-tags').removeClass('hide');
          $.scrollTo(0, 0);
        },
      });
      return false;

    });
  });

  $('[data-action="parti-confirm-merge"]').each(function(index, elm){
    $(this).on('click',function (e){
      var source = $($(this).data('source')).val()
      var target = $($(this).data('target')).val()
      return confirm( '----------------------------------------\n지워지는 채널와 위키: ' + source + '\n합해지는 채널: ' + target + '\n\n이대로 진행하시겠습니까? 이 행위는 되돌릴 수 없습니다.\n----------------------------------------')
    });
  });

  // 화면 분할
  (function() {
    $('.js-content-split-container').each(function() {
      var $elm = $(this);
      var top_space = parseInt($elm.css('margin-top'), 10) + parseInt($elm.css('padding-top'), 10);

      var bottom_space = parseInt($elm.css('margin-bottom'), 10) + parseInt($elm.css('padding-bottom'), 10)

      var on_resize = function() {
        var inner_height = $('body').height() - ($elm.position().top - $('.js-fixed-header').height());

        $elm.find('.js-content-split-right').css('height', inner_height).css('overflow-y', 'auto').css('border-left', '1px solid #c0c0c2').css('padding-top', top_space + 'px').css('padding-bottom', bottom_space + 'px');
        $elm.find('.js-content-split-left').css('height', inner_height).css('overflow-y', 'auto').css('padding-bottom', bottom_space + 'px');

        if ($elm.hasClass('js-content-split-container-no-padding')) {
          $elm.find('.js-content-split-left').css('padding-left', 0).css('padding-right', 0).css('padding-top', 0);
        } else {
          $elm.find('.js-content-split-left').css('padding-top', top_space + 'px')
        }

        $elm.css('padding-top', 0).css('margin-top', 0).css('padding-bottom', 0).css('margin-bottom', 0);
      }
      on_resize();
      $(window).on('resize', on_resize);
    });
  })();
});