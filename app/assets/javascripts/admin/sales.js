var Minibar = window.Minibar || {};

Minibar.salesItem = function(saleTypeEl, saleIdEl){

    console.log(saleTypeEl, saleIdEl);

    saleTypeEl.change(function() {
        var url = $(this).data("url");
        var value = $(this).val();

        jQuery.get(url , { type: value }, function(data){
          saleIdEl.html('')
          $.each(data, function(id, pair){
            saleIdEl.append($('<option></option>').attr('value', pair[1]).html(pair[0]))
          });
        });

        saleIdEl.trigger('lizst:updated');

        return false;
  });
}