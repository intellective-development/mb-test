const user_agent = window.navigator && window.navigator.userAgent;
const mobileUAChecks = {
  Android(){
    return /Android/i.test(user_agent);
  },
  BlackBerry(){
    return /BlackBerry/i.test(user_agent);
  },
  iOS(){
    return /iPhone|iPad|iPod/i.test(user_agent);
  },
  iPad(){
    return /iPad/i.test(user_agent);
  },
  Opera(){
    return /Opera Mini/i.test(user_agent);
  },
  Windows(){
    return /IEMobile/i.test(user_agent);
  },
  any(){
    return (mobileUAChecks.Android() || mobileUAChecks.BlackBerry() || mobileUAChecks.iOS() || mobileUAChecks.Opera() || mobileUAChecks.Windows());
  }
};


const mobile_max_width = 768;
const mobile_class_name = 'is-mobile';

const widthChangedWatcher = function(changedCallback){
  const $window = $(window);
  let last_window_width = $window.width();

  $window.resize(() => {
    const window_width = $window.width();

    if (last_window_width !== window_width){
      changedCallback(window_width);
      last_window_width = window_width;
    }
  });
};

const isMobileWidth = function(width){
  return width < mobile_max_width;
};

const manageMobileBodyClass = function(){
  let last_is_mobile = (isMobileWidth($(window).width()));
  if (last_is_mobile){
    $('body').addClass(mobile_class_name);
  }

  widthChangedWatcher((new_width) => {
    const is_mobile = isMobileWidth(new_width);
    if (is_mobile && !last_is_mobile){ // if it's changed to mobile
      $('body').addClass(mobile_class_name);
    } else if (!is_mobile && last_is_mobile){ // if it's changed from mobile
      $('body').removeClass(mobile_class_name);
    } //otherwise, it's unchanged, don't mess with the DOM
    last_is_mobile = is_mobile;
  });
};

export {manageMobileBodyClass, mobileUAChecks, isMobileWidth};
