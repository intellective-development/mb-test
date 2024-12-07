var Minibar = window.Minibar || {};

function registerChildProductListeners(){
  $('.variant-table__toggle').click(function(){
    $(this).toggleClass('shown');
    $(this).siblings('.variant-table').toggleClass('shown');
  });

  $('.variant-table__new-variant').click(function(){
    clearNewVariantFormFields();
    var product_id = $(this).data('product-id');
    var product_volume = $(this).data('product-volume');
    $('#new-variant__form').attr('action', "/admin/merchandise/products/" + product_id + "/add_variant");
    $('#new-variant__id').val(product_id);
    $('#new-variant__volume').text(product_volume);
    $('#new-variant').foundation('reveal', 'open');
  });

  $('#new-variant__form').submit(function(){
    $('#new-variant').foundation('reveal', 'close');
  });

  // this implementation updates the variant count immediately, but doesn't update the url and it's params
  $("#new-variant__form").on("ajax:success", function(e, data, status, xhr){
    document.open();
    document.write(xhr.responseText);
    document.close();
  });

  function clearNewVariantFormFields(){
    $('#new-variant__form input[type=text]').val('');
  }
}

function toggleSpinnerAndEmpty(container){
  if(!jQuery.trim(container.html()).length){
    container.html("<div class='spinner'></div>");
  }else{
    container.html("");
  }
}

$("#sizes-tab").click(function(){
  var grouping_id = $(this).data('grouping-id');
  var sizes_panel = $('#sizes');
  if(!jQuery.trim(sizes_panel.html()).length){ // keeps from requesting if already loaded
    $.ajax({
      type: 'GET',
      url: '/admin/merchandise/product_size_groupings/' + grouping_id + '/child_products',
      dataType: 'html',
      beforeSend: function() {
        toggleSpinnerAndEmpty(sizes_panel);
      },
      complete: function(data) {
        toggleSpinnerAndEmpty(sizes_panel);
        $('#sizes').html(data.responseText);
      }
    });
  }
});
