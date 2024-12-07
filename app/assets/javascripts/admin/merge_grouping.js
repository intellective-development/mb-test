/****************************************
* Merge two product groupings' information
* from data object in the view
* at /app/views/admin/merchandise/merge_groupings/
*****************************************/

$(function(){
  var selectizeRemoteOptions = function(list){
    return {
      valueField: 'id',
      searchField: ['name', 'item_volume'],
      sortField: 'name',
      labelField: 'name',
      loadThrottle: 500,
      create: false,
      score: function(search) {
        return function(item) {
          return item.master == true ? 2 : 1
        }
      },
      load: function(query, callback) {
        if (query.length < 4) return callback(); //don't search under 4 chars
        if (!query.length) return callback();
        $.ajax({
          url: Data.remote_url,
          type: 'GET',
          dataType: 'json',
          contentType: 'application/json',
          data: {
            list: list,
            term: query,
            out_of_stock: Data.out_of_stock,
            pending: Data.pending
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
      searchField: ['name', 'item_volume'],
      sortField: 'name',

      create: false,
      options: Data.destroy_product_grouping_list,
      render: {
        option: function(item, escape) {
          return cellTemplate(item, escape);
        }
      }
    }
  };


  $('.product-grouping-select-1').selectize(selectizeRemoteOptions("mergee")); //init
  var selectize_1 = $('.product-grouping-select-1')[0].selectize; //get object

  var opts = (Data.show_all ? selectizeRemoteOptions("merged") : selectizeLoadOptions());
  $('.product-grouping-select-2').selectize(opts); //if supplier chosen -> load products, otherwise search
  var selectize_2 = $('.product-grouping-select-2')[0].selectize;

  $('.selectize-input').click(function(event){ //clears the current selection on click
    var parent = $(this).parent();
    if (parent.hasClass("product-grouping-select-1")){
      selectize_1.clear();
    } else {
      selectize_2.clear();
    }
  });


  $(".product-grouping-count").text(Data.destroy_product_grouping_list.length);
  var product_grouping_selects = $('select.product-grouping-select-1, select.product-grouping-select-2');

  product_grouping_selects.change(function(e){//pulls down the data for the two panels
    var el = $(e.target),
        value = el.val(),
        target = el.attr("id") === "product_grouping_id_1" ? 'p1' : 'p2';
    if (value != ""){ //so you don't pull down index.html if no val
      $.get('/admin/merchandise/merge_groupings/' + value, function(response){
        $("#" + target).html(response);
        updateSwapUrl();
      });

      $("#replace_name", '#control-panel').prop("checked", false);
      $("#replace_description", '#control-panel').prop("checked", false);
      $("#replace_image", '#control-panel').prop("checked", false);
      $("#replace_category", '#control-panel').prop("checked", false);
      // $("#merge_properties", '#control-panel').prop("checked", true);
      $("#activate", '#control-panel').prop("checked", false);
    }
  });

  $('#button_merge').click(function(){//does the merging
    $('#status').html('');
    var leftVolume = $('#p1 h5 .volume').text(),
      rightVolume = $('#p2 h5 .volume').text();

    $.ajax({
      url: Data.merge_url,
      data: {
        target: $('#p1 h5').attr('id'),
        source: $('#p2 h5').attr('id'),
        replace_name: $('#replace_name').prop('checked'),
        replace_description: $('#replace_description').prop('checked'),
        replace_image: $('#replace_image').prop('checked'),
        replace_category: $('#replace_category').prop('checked'),
        merge_properties: $('#merge_properties').prop('checked'),
        activate: $('#activate').prop('checked')
      },
      dataType: 'json',
      method: 'PUT',
      success: function(response){
        $('#status').html('Merged!');
        removeMerged();
        $('#p2').html("");
      },
      error: function(jqXHR, textStatus, errorThrown){
        var links = '';
        if(jqXHR.typeof  != 'undefined'){
          var jsonResponse = jqXHR.responseJSON || JSON.parse(jqXHR.responseText) || jqXHR.responseText;
          if (jsonResponse) {
            if (jsonResponse.text == "NoPossibleMerge") {
              $('#status').html(jsonResponse.side + ' Grouping with <span><b>id: ' + jsonResponse.id + "</b></span> can't be merged");
            } else if (jsonResponse.text == "ProductsNeedMergingError") {
              jsonResponse.products.forEach(function (pair, index) {
                links += mergeOptionsPair(pair.dest_name, pair.source_name, pair.merge_link, pair.volume_details);
              });
            } else {
              links += jsonResponse;
            }
          }
          $('#productMergeDeeplinkList').html(links);
          $('#mergeProductsPrompt').foundation('reveal', 'open');
        }
      }
    });
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
      params.source_grouping_id = destination;
    }
    if(typeof source != 'undefined'){
      params.destination_grouping_id = source;
    }
    return "?" + $.param(params);
  };

  var removeMerged = function(){ //remove element from options list
    var product_grouping_id = $('#p2 h5').attr('id');

    try{
      selectize_2.removeOption(product_grouping_id);
    }catch(err){
      Raven.captureMessage(err.message);
    }
  };

  var cellTemplate = function(item, escape){
    var title = escape(item.name)
    if (item.master) {
      title = title + ' - ⭐'
    }
    var template =
      '<div class="search-cell-'+escape(item.state)+'">' +
        '<span class="title">' +
          '<span>' + title + '</span>' +
        '</span>' +
        '<ul class="meta">' +
          '<li>' + 'id: ' + escape(item.id) + '</li>' +
          '<li>' + 'products: ' +  escape(item.products_count) + '</li>' +
          '<li>' + 'state: ' + escape(item.state) + '</li>' +
        '</ul>' +
      '</div>'
    return template
  }

  var mergeOptionsPair = function(destination_name, source_name, merge_link, volume_details){
    var template =
      '<div class="row">' +
        '<div class="large-4 columns">' + '<p>' + destination_name + '</p>' + '</div>' +
        '<div class="large-2 columns">' + '<span>&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;</span>' + '<span><p>' + volume_details + '</p></span>' + '</div>' +
        '<div class="large-4 columns">' + '<p>' + source_name + '</p>' + '</div>' +
        '<div class="large-2 columns">' + '<a href="' + merge_link + '" class="button" target="_blank">' + 'Merge' + '</a>' + '</div>' +
      '</div>'
    return template
  }

});
