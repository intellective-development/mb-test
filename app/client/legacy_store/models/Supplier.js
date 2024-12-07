import _ from 'lodash';
import { BackboneRXModel } from 'shared/utils/backbone_rx';

const Supplier = BackboneRXModel.extend({
  url: function(){
    return `${window.api_server_url}/api/v2/supplier/` + this.get('id');
  },
  initialize: function(attributes){
    this.setDeliveryMethods();
    this.on('change:delivery_methods', this.setDeliveryMethods);
    this.active = true;
  },

  fetch: function(options){ // UNUSED?
    options = options || {};
    options.data = {
      ...options.data,
      ...Store.DeliveryAddress.formatAddress()
    };
    return Backbone.Collection.prototype.fetch.call(this, options);
  },
  setDeliveryMethods: function(){ // INTERNAL
    var current_delivery_methods = this.get('delivery_methods');
    var delivery_method_coll = new DeliveryMethodCollection(current_delivery_methods);
    this.set('delivery_methods', delivery_method_coll, {silent: true});
    if (!this.get('delivery_methods').any()){
      Raven.captureMessage('Supplier without delivery method',
                            { extra: { supplier: this.attributes, delivery_methods: current_delivery_methods }});
    }
  },
  getSelectedDeliveryMethod(){
    return this.get('delivery_methods').find(delivery_method => delivery_method.id === this.get('selected_delivery_method_id'));
  },
  toPure: function(){
    const delivery_methods = this.get('delivery_methods').toPure();
    return _.extend({}, this.attributes, {delivery_methods: delivery_methods});
  }
});

export default Supplier;
