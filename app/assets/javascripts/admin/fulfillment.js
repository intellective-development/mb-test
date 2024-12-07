jQuery(document).ready(function($) {
  $("#create-shipment-button").click(function() {
    var url = $(this).data("url");
    jQuery.ajax( {
      type : "PUT",
      url : url,
      dataType: 'script'
    });
    return false;
  });
});

var Minibar = window.Minibar || {};

Minibar.Fulfillment = {
  captureInvoiceButton      : '#capture-invoice-button-',
  capturePartInvoiceButton  : '#capture-partial-invoice-button-',
  cancelInvoiceButton       : '#cancel-invoice-button-',
  confirmOrderButton        : '#confirm_order_button',
  orderId                   : null,

  initialize : function(invoiceId, order_id) {

    var captureTag      = jQuery(Minibar.Fulfillment.captureInvoiceButton + invoiceId );
    var capturePartTag  = jQuery(Minibar.Fulfillment.capturePartInvoiceButton + invoiceId);
    var cancelTag       = jQuery(Minibar.Fulfillment.cancelInvoiceButton + invoiceId);
    var confirmTag      = jQuery(Minibar.Fulfillment.confirmOrderButton);
    Minibar.Fulfillment.orderId = order_id;

    jQuery("#dialog").dialog({
      bgiframe: true,
      autoOpen: false,
      height: 190,
      width: 460,
      modal: true
    });

    confirmTag.bind('click', function(e){
      var url = jQuery(e.target).attr('href');

      Minibar.Fulfillment.confirmOrder(url);

      return false;
    });

    captureTag.bind('click',function(){
        // submit to collect all payments
        Minibar.Fulfillment.captureInvoice(invoiceId);
    });

    capturePartTag.bind('click',function() {
        // submit to go to capture part form
        // capture part form has cancel order-items
    });

    cancelTag.bind('click', function() {
        // submit to go to cancel order and payment
        Minibar.Fulfillment.cancelInvoice(invoiceId);
    });
  },//END of INITIALIZE

  confirmOrder: function(url){
    jQuery(Minibar.Fulfillment.confirmOrderButton).text('Processing...');

    jQuery.ajax({
      type: "POST",
      url: url,
      data: { },
      success: function(){
        jQuery(Minibar.Fulfillment.confirmOrderButton).text('Confirmed!').unbind('click');
      },
      error: function(){
        jQuery(Minibar.Fulfillment.confirmOrderButton).text('Error Confirming, please retry.');
      }
    });
  },


  captureInvoice : function(invoiceId) {
    jQuery('#dialog').dialog( 'option', 'buttons', [
        {
          text: "OK" ,
          click: function() {
            // Make an ajax request to cancel the invoice
            jQuery.ajax( {
              type : "PUT",
              url : '/admin/fulfillment/orders/' + Minibar.Fulfillment.orderId ,
              data : {invoice_id : invoiceId, amount : 'all' } ,
              complete : function(htmlText) {
                if (htmlText.status == 200) {
                  //jQuery('#invoice-line-' + invoiceId).html( htmlText.responseText);
                  //$(this).dialog("close");
                  jQuery('#dialog-message').html(htmlText.responseText);
                } else {
                  jQuery('#dialog-message').html(htmlText.responseText);
                }
              },
              dataType : 'html'
            });
          }
        },
        {
          text: "Close",
          click: function() { $(this).dialog("close"); }
        }
      ]
    );
    jQuery('#dialog-message').html('Are you sure you want to COLLECT FUNDS for this order?');
    jQuery('#dialog-message').css('background-color', '#CFD');
    jQuery('#dialog').dialog('open');
    return false;
  },// cancelInvoice
  cancelInvoice : function(invoiceId) {

    jQuery('#dialog').dialog( 'option',
                              'buttons',
                              [
                                {
                                  text: "OK" ,
                                  click: function() {
                                    // Make an ajax request to cancel the invoice
                                    jQuery.ajax( {
                                      type : "DELETE",
                                      url : '/admin/fulfillment/orders/' + Minibar.Fulfillment.orderId ,
                                      data : {invoice_id : invoiceId } ,
                                      complete : function(htmlText) {
                                        if (htmlText.status == 200) {
                                          jQuery('#invoice-line-' + invoiceId).html( htmlText.responseText);
                                          jQuery('#dialog').dialog("close");
                                        } else {
                                          jQuery('#dialog-message').html('Sorry there was an error.');
                                        }

                                      },
                                      dataType : 'html'
                                    });
                                  }
                                },
                                {
                                  text: "Close",
                                  click: function() { $(this).dialog("close"); }
                                }
                              ]
                            );
    jQuery('#dialog-message').html('Are you sure you want to CANCEL the Order and Shipment?');
    jQuery('#dialog-message').css('background-color', '#FCD');
    jQuery('#dialog').dialog('open');
    return false;
  }// cancelInvoice
};

jQuery(function() {
  jQuery.each(jQuery('.order-invoice'), function(index, obj){
    Minibar.Fulfillment.initialize(jQuery(obj).data('invoice_id'), jQuery(obj).data('order_id'));
  })

});
