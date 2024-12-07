var Minibar = window.Minibar || {};

Minibar.Utility = {
  registerOnLoadHandler : function(callback) {
    jQuery(window).ready(callback);
  }
}

Minibar.AdminMerchandiseProductForm = {

  productCheckboxesDiv  : '#product_properties',
  productTypeSelectId   : '#product_product_type_id',
  formController        : '/admin/merchandise/products',
  productId             : null,

  initialize : function(product_Id, remote_url) {
    this.productId  = product_Id;
    this.remote_url = remote_url;
    var brand       = jQuery(Minibar.AdminMerchandiseProductForm.brandSelectId);
    var product_type   = jQuery(Minibar.AdminMerchandiseProductForm.productTypeSelectId);

    product_type.bind('change',function() {
      var id =  jQuery(Minibar.AdminMerchandiseProductForm.productTypeSelectId + " option:selected").first().val();
      Minibar.AdminMerchandiseProductForm.getProperties(id)
    });

    this.additional_upc = this.initializeAdditionalUPCs();

    this.clone_select = this.initializeCloneSelect();
    $('.selectize-input').click(this.emptySelectize)
  },

  getProperties : function(id) {
    if ( id === '' ){
      return false; //don't show properties when dumping it
    }
    else if ( typeof id == 'undefined' || id == 0 ) {
      //  show all properties...
      $('#product_properties').children().fadeIn();
      //jQuery(Minibar.AdminMerchandiseProductForm.productCheckboxesDiv).html('');
    }
    else {
      jQuery.ajax( {
         type : "GET",
         url : MerchProductForm.formController + '/' + id + "/add_properties",
         data : { product_id : Minibar.AdminMerchandiseProductForm.productId },
         complete : function(json) {
           // open dialog with html
           Minibar.AdminMerchandiseProductForm.refreshProperties(json);
          // STOP  WAIT INDICATOR...
         },
         dataType : 'json'
      });
    }
  },

  refreshProperties : function(json) {
    properties = JSON.parse(json.responseText);

    jQuery.each (properties.active, function(p,value) {
      jQuery('#property_' + value ).fadeIn();
    });

    jQuery.each (properties.inactive, function(p,value) {
      propertyId = '#property_' + value;
      jQuery(propertyId ).hide();
      jQuery(propertyId + ' input:text')[0].value = '';
    });
  },

  initializeAdditionalUPCs: function(){
    if ($('.additional-upcs').children().length < 1) { return null; }
    $('.additional-upc-delete').click(function(e) {
      e.preventDefault();
      var response = confirm($(this).data('confirm') || 'Are you sure?');
      if (!response) { return null; }
      var del_upc = $(this)
        .next()
        .text();
      var upcs = [];
      $(this)
        .parent()
        .remove();
      $('.upc').each(function() {
        var upc = $(this).text();
        if (upc !== del_upc) {
          upcs.push(upc);
        }
      });
      $('#product_additional_upcs').val(upcs);
    });
    $('#delete-all-upcs').click(function(e) {
      e.preventDefault();
      var response = confirm($(this).data('confirm') || 'Are you sure?');
      if (!response) { return null; }
      $('.additional-upc').remove();
      $('#product_additional_upcs').val([]);
    });
  },

  initializeCloneSelect: function(){
    // clone tool dropdown
    var remote_url  = this.remote_url;
    var selectize_remote_options = {
      valueField: 'id',
      searchField: ['name', 'item_volume'],
      sortField: 'name',
      labelField: 'name',
      loadThrottle: 500,
      create: false,
      load: function(query, callback) {
        if (query.length < 4) return callback(); //don't search under 4 chars
        if (!query.length) return callback();
        $.ajax({
          url: remote_url,
          type: 'GET',
          dataType: 'json',
          data: {
            term: query,
          },
          error: function(xhr, ajaxOptions, thrownError) {
            callback();
          },
          success: function(results) {
            callback(results);
          }
        });
      },
      render: {
        option: function(item, escape) {
          return '<div class="search-cell-'+escape(item.state)+'">' +
            '<span class="title">' +
              '<span>' + escape(item.name) + ' - ' + escape(item.item_volume) + '</span>' +
            '</span>' +
            '<ul class="meta">' +
              '<li>' + 'variants: ' +  escape(item.variant_count) + '</li>' +
              '<li>' + 'state: ' + escape(item.state) + '</li>' +
            '</ul>' +
          '</div>';
        }
      }
    };

    $('select.product-select-1').change(function(e){//on select
      var el = $(e.target),
          clone_product_id = el.val();
      $.ajax({
        url: '/admin/merchandise/products/' + clone_product_id,
        data: {},
        dataType: 'json',
        method: 'GET',
        success: function(response){
          $('small.error').remove(); //remove any prev found

          //product's attributes
          $.each(response, function(attr, value){
            el = $(":input#product_"+attr);
            markField(el, value);
          });

          //product_properties
          $.each(response.properties, function(attr, p_property){
            el = $("#property-input-"+p_property.property_id+":text");
            markField(el, p_property.value);
          });

          //image
          var img_field = $(".js-product-image");
          markField(img_field, response.image_url);

          setAttrClickListener();
        }
      });
    });

    var markField = function(el, value){
      if (el.length !== 0 && value !== undefined && value !== null && value !== ""){
        // test for if it's an array or string:
        if (typeof(value) === 'object') {
          el.after("<small class='error products' data-val="+escape(value[0])+">"+value[1]+"</small>");
        } else{
          el.after("<small class='error products' data-val='"+escape(value)+"'>"+value+"</small>");
        }
      }
    }

    var setAttrClickListener = function(){
      $('small.error').click(function(e){ //click any fillers to replace
        var current = $(e.target);
        var field   = current.prev(':input');
        field.val(unescape(current.data("val")));
        current.remove();
      });
    }
    $('.product-select-1').selectize(selectize_remote_options); //init
    return $('.product-select-1')[0].selectize; //get object
  },
  emptySelectize: function(event){
    var parent = $(this).parent(),
        form = Minibar.AdminMerchandiseProductForm;
    if (parent.hasClass("product-select-1")){
      form.clone_select.clear();
    }
  }

};


MerchProductForm = Minibar.AdminMerchandiseProductForm;
