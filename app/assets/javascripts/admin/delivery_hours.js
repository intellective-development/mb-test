$(".add-hours-row").click(function (event) {
  const parent = $(this).parent().parent();
  var pos = parent.parent().children().length - 1;
  const row_root = $('<div class="row"></div>')
    .append($('<div class="small-3 column"><label>&#8203;</label></div>'))
    .append(
      $(
        '<div class="small-3 column"><input type="hidden" value="' +
          parent.find('[type="hidden"]')[0].value +
          '" name="shipping_method[delivery_hours][' +
          pos +
          '][wday]" id="shipping_method_delivery_hours_' +
          pos +
          '_wday"></div>'
      )
    )
    .append(
      $('<div class="small-4 column"></div>').append(
        $(
          '<input class="ui-timepicker hasDatepicker" type="text" value="00:00 am" name="shipping_method[delivery_hours][' +
            pos +
            '][starts_at]" id="shipping_method_delivery_hours_' +
            pos +
            '_starts_at">'
        )
      )
    )
    .append(
      $('<div class="small-4 column"></div>').append(
        $(
          '<input class="ui-timepicker hasDatepicker" type="text" value="00:01 am" name="shipping_method[delivery_hours][' +
            pos +
            '][ends_at]" id="shipping_method_delivery_hours_' +
            pos +
            '_ends_at">'
        )
      )
    )
    .append(
      $(
        '<div class="small-1 column" style="height:34px;display:flex;align-items:center;"><a class="remove-hours-row" data-remote="true" href="#">❌</a></div>'
      )
    );
  row_root.insertAfter(parent);
});

$(".remove-hours-row").click(function (event) {
  const parent = $(this).parent().parent();
  parent.remove();
});

$("#supplier_delivery_service_id").on('change', function(e) {
  const index = this.selectedIndex
  const dsp = this.options[index].text
  if (dsp !== 'CartWheel' && dsp !== '') {
    $(".additional-dsp").removeClass('hide')
    $("#add_secondary_delivery_service")[0].checked = false
  } else {
    $(".additional-dsp").addClass('hide')
    $("#add_secondary_delivery_service")[0].checked = false
  }
});
