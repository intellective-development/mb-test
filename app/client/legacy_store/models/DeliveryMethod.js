import { BackboneRXModel } from 'shared/utils/backbone_rx';

const DeliveryMethod = BackboneRXModel.extend({ // only used by collection
  supplier: function(){ // unused?
    return Store.Suppliers.get(this.get('supplier_id'));
  }
});

export default DeliveryMethod;

//TODO: remove! use real dependencies!
window.DeliveryMethod = DeliveryMethod;
