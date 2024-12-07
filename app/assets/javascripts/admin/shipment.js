var Minibar = window.Minibar || {};

if (typeof Minibar.Admin == "undefined") {
  Minibar.Admin = {};
}

Minibar.Admin.toggleNotificationMethodSelect = function() {
  if ($('#notification_method').prop('disabled')) {
    $('#notification_method').prop('disabled', false);
  } else {
    $('#notification_method').prop('disabled', true);
  }
}
