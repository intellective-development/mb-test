var Minibar = window.Minibar || {};
// If we already have the Appointments namespace don't override
if (typeof Minibar.Admin == "undefined") {
    Minibar.Admin = {};
}
var kk = null;
Minibar.Admin.defaultTwoForOneDiscount = 0.05;

// If we already have the Appointments object don't override
if (typeof Minibar.Admin.products == "undefined") {

    Minibar.Admin.products = {
        //scheduled_at    : null,
        initialize      : function( ) {
          // If the user clicks add new variant button
          jQuery('.add_variant_child').on('click', function() {
            Minibar.Admin.products.addVariant();// product_table_body
          });
          jQuery('.add_all_supplier').on('click', function() {
            Minibar.Admin.products.addAllVariant();// product_table_body
          });

          jQuery('.remove_variant_child').on('click', function() {
            Minibar.Admin.products.removeVariant(this);// product_table_body
          });
        },
        addVariant : function(){
          var content =  $('#variants_fields_template').html() ;
          var regexp  = new RegExp('new_variants', 'g');
          var new_id  = new Date().getTime();
          $('#variants_container').append(content.replace(regexp, new_id));
          return false;
        },
        addAllVariant : function(){
          $('#variants_container .variant-check').prop('checked', true);
          return false;
        },

        removeVariant : function(obj){
          kk = obj;
          jQuery(obj).closest( '.new_variant_container' ).html('');
        }
    };

    jQuery(function() {
      Minibar.Admin.products.initialize();
    });
};

Minibar.Admin.toggleTwoForOneInput = function(id) {      // this can be triggered using :onclick
  if ($('#two_for_one-' + id).prop('disabled')) {
    $('#two_for_one-' + id).prop('disabled', false);
    $('#two_for_one-' + id).val(Minibar.Admin.defaultTwoForOneDiscount);
  } else {
    $('#two_for_one-' + id).prop('disabled', true);
    $('#two_for_one-' + id).val(null);
  }
}
