import helpers from './utils/utils';
import handlebars_helpers from './utils/handlebars_helpers';
import vendor_manifest from './vendor_manifest';
import initFoundation from './utils/init_foundation';

// boot up the store
$(function(){
  console.log('booting up the store');
  initFoundation(); // TODO: why do we need foundation?
  if(window.Data && window.Data.SupplierIds) {
    gtag('event', 'supplier_ids_dimension', { 'supplier_ids': window.Data.SupplierIds }); // TODO: do we need gtag
  }
  console.log('booted up the store');
});
