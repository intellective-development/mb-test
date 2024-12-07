//=require vendor/jquery2
//=require vendor/smooth-scroll

$(function() {
  smoothScroll.init();

  $(".faq .title").on("click touch", function(e) {
    e.preventDefault();

    var el = $(this), content = el.next(".content");

    content.toggleClass("open");
    el.toggleClass("open");
  });
});
