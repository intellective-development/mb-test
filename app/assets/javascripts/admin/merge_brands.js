/****************************************
* Merge two brands information
* from data object in the view
* at /app/views/admin/merchandise/merge_brands/
*****************************************/

$(function(){
    var selectizeRemoteOptions = function(list){
      return {
        valueField: 'id',
        searchField: ['name'],
        sortField: 'name',
        labelField: 'name',
        loadThrottle: 500,
        create: false,
        load: function(query, callback) {
          if (query.length < 2) return callback(); //don't search under 2 chars
          if (!query.length) return callback();
          $.ajax({
            url: Data.remote_url,
            type: 'GET',
            dataType: 'json',
            contentType: 'application/json',
            data: {
              list: list,
              term: query
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
            return cellTemplate(item, escape);
          }
        }
      }
    };

    var selectizeLoadOptions = function(){ //initializes second (supplier) select
      return {
        valueField: 'id',
        labelField: 'name',
        searchField: ['name'],
        sortField: 'name',

        create: false,
        options: [],
        render: {
          option: function(item, escape) {
            return cellTemplate(item, escape);
          }
        }
      }
    };
    $('.product-select-1').selectize(selectizeRemoteOptions("mergee")); //init
    var selectize_1 = $('.product-select-1')[0].selectize; //get object
    var opts = (Data.show_all ? selectizeRemoteOptions("merged") : selectizeLoadOptions());
    $('.product-select-2').selectize(opts); //if supplier chosen -> load products, otherwise search
    var selectize_2 = $('.product-select-2')[0].selectize;

    $('.selectize-input').click(function(event){ //clears the current selection on click
      var parent = $(this).parent();
      if (parent.hasClass("product-select-1")){
        selectize_1.clear();
      } else {
        selectize_2.clear();
      }
    });

    var brand_selects = $('select.product-select-1, select.product-select-2')

    brand_selects.change(function(e){//pulls down the data for the two panels
      var el = $(e.target),
          value = el.val(),
          target = el.attr("id") === "product_id_1" ? 'p1' : 'p2';
      if (value != ""){ //so you don't pull down index.html if no val
        $.get('/admin/merchandise/merge_brands/' + value, function(response){
          $("#" + target).html(response);
          updateSwapUrl();
        });

        $("#replace_name", '#control-panel').prop("checked", false);
        $("#replace_description", '#control-panel').prop("checked", false);
        $("#replace_image", '#control-panel').prop("checked", false);
        $("#replace_category", '#control-panel').prop("checked", false);
        $("#merge_properties", '#control-panel').prop("checked", true);
        $("#remove_upc", '#control-panel').prop("checked", false);
        $("#activate", '#control-panel').prop("checked", false);
      }
    });

    $('#button_merge').click(function(){//does the merging
      $('#status').html('');
      var leftVolume = $('#p1 h5 .volume').text(),
        rightVolume = $('#p2 h5 .volume').text();

      if(passVolumeCheck(leftVolume, rightVolume)){
        $.ajax({
          url: Data.merge_url,
          data: {
            target: $('#p1 h5').attr('id'),
            source: $('#p2 h5').attr('id'),
            replace_name: $('#replace_name').prop('checked'),
            replace_description: $('#replace_description').prop('checked'),
            merge_properties: $('#merge_properties').prop('checked'),
          },
          dataType: 'json',
          method: 'PUT',
          success: function(response){
            $('#status').html('Merged!');
            removeMerged();
            $('#p2').html("");
          },
          error: function(jqXHR, textStatus, errorThrown){
            Raven.captureMessage(jqXHR.responseText);
            if(jqXHR.responseJSON.text == "NoPossibleMerge"){
              $('#status').html(jqXHR.responseJSON.side + ' Brand with <span><b>id: ' + jqXHR.responseJSON.id + "</b></span> can't be merged");
            }else{
              $('#status').html('Cannot Merge!');
            }
          }
        });
      }
    });

    var updateSwapUrl = function(){
      $('a.swap-merge-icon').attr('href',function(i, val){
        return (val.split("?")[0]) + calculateSwapParams();
      });
    };

    var calculateSwapParams = function(){
      var destination = $('#p1 h5').attr('id');
      var source = $('#p2 h5').attr('id');
      var params = {};

      if(typeof destination != 'undefined'){
        params.source_id = destination;
      }
      if(typeof source != 'undefined'){
        params.destination_id = source;
      }
      return "?" + $.param(params);
    };

    var passVolumeCheck = function(volume1, volume2){
      return volume1 == volume2 || (volume1 !== volume2 && confirm("Warning: Different Volumes!\n\nMerge  " + (volume2 || "null") + "  into  " + (volume1 || "null") + "  ?\n\n"))
    };

    var removeMerged = function(){ //remove element from options list
      var product_id = $('#p2 h5').attr('id');

      try{
        selectize_2.removeOption(product_id);
      }catch(err){
        Raven.captureMessage(err.message);
      }
    };

    var cellTemplate = function(item, escape){
      var template =
        '<div class="search-cell search-cell-'+escape(item.name)+'">' +
          '<span class="title">' +
            '<span>' + escape(item.name) + '</span>' +
          '</span>' +
          '<ul class="meta">' +
            '<li>' + 'id: ' + escape(item.id) + '</li>' +
            '<li>' + 'Product Groupings: ' +  escape(item.groupings_count) + '</li>' +
            '<li>' + 'Sub Brands: ' + escape(item.sub_brands_count) + '</li>' +
          '</ul>' +
        '</div>';
      return template
    }

  });
