jQuery(document).ready(function() {
  jQuery("input.ui-datepicker").datepicker();

  try {
    jQuery("input.ui-timepicker").timepicker({
      hourGrid: 4,
      minuteGrid: 10,
      timeFormat: "hh:mm tt"
    });
  } catch (e) {
  }

  jQuery(
    "input.ui-futurepicker"
  ).datepicker({ yearRange: "2010:2020", changeYear: true });
  jQuery("input.ui-yearpicker").datepicker({
    yearRange: "1910:2000",
    changeYear: true,
    constrainInput: true,
    showOn: "focus"
  });
});
