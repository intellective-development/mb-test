//=require vendor/jquery2
//=require jquery_ujs
//=require vendor/jquery.simulate
//=require vendor/jquery.validate
//=require vendor/jquery.validate.additional
//=require vendor/store.js
//=require vendor/base64.js
//=require handlebars.runtime
//=require vendor/foundation/foundation
//=require vendor/foundation/foundation.alerts
//=require vendor/foundation/foundation.abide
//=require vendor/foundation/foundation.cookie
//=require vendor/foundation/foundation.dropdown
//=require vendor/foundation/foundation.forms
//=require vendor/foundation/foundation.magellan
//=require vendor/foundation/foundation.reveal
//=require vendor/foundation/foundation.section
//=require vendor/foundation/foundation.topbar
//=require vendor/foundation/foundation.placeholder
//=require vendor/underscore.string.js

window.isMobile = {
  Android: function() {
    return navigator.userAgent.match(/Android/i);
  },
  BlackBerry: function() {
    return navigator.userAgent.match(/BlackBerry/i);
  },
  iOS: function() {
    return navigator.userAgent.match(/iPhone|iPad|iPod/i);
  },
  iPad: function() {
    return navigator.userAgent.match(/iPad/i);
  },
  Opera: function() {
    return navigator.userAgent.match(/Opera Mini/i);
  },
  Windows: function() {
    return navigator.userAgent.match(/IEMobile/i);
  },
  any: function() {
    return isMobile.Android() ||
      isMobile.BlackBerry() ||
      isMobile.iOS() ||
      isMobile.Opera() ||
      isMobile.Windows();
  }
};

if (!window.btoa) window.btoa = base64.encode;
if (!window.atob) window.atob = base64.decode;

function utf8_to_b64(str) {
  return window.btoa(unescape(encodeURIComponent(str)));
}

function b64_to_utf8(str) {
  return decodeURIComponent(escape(window.atob(str)));
}

function initModuleLinks() {
  var $modules = $(".module[data-url]");
  $modules.each(function(i, module) {
    $(module).click(function(e) {
      var $module = $(e.target).closest(".module"), url = $module.data("url");
      window.location = url;
    });
  });
}

$(function() {
  $(document).foundation(); //re-inits foundation, currently just lets hitting escape work
  $(document).foundation().foundation("reveal", {
    animation: "fadeAndPop",
    animationSpeed: 0
  });

  if (isMobile.any()) {
    $("body").addClass("is-mobile");
  }

  initModuleLinks();
});

$("[data-slide-id]").click(function() {
  var el = $(this),
    slideId = el.data("slide-id"),
    activeEl = $(".active[data-slide-id]"),
    activeSlideId = activeEl.data("slide-id");

  $("[data-slide-id]").removeClass("active");
  if (activeSlideId) {
    $(activeSlideId).slideToggle(80, function() {
      if (activeSlideId != slideId) {
        $(slideId).slideToggle(80);
        el.addClass("active");
      }
    });
  } else {
    $(slideId).slideToggle(80);
    el.addClass("active");
  }

  return false;
});
