//= require jquery2
//= require jquery_ujs
//= require extras
//= require best_in_place
//= require local_time
//= require bxslider

$(function () {
  $(".best_in_place").best_in_place();

  // for about view
  $('.bxslider').bxSlider({
    mode: 'vertical',
    controls: false,
    adaptiveHeight: true,
    auto: true,
    pager: false
  });
});
