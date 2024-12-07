import { BackboneRXCollection } from 'shared/utils/backbone_rx';

const DeliveryMethodCollection = BackboneRXCollection.extend({
  model: DeliveryMethod
});

export default DeliveryMethodCollection;

//TODO: remove! use real dependencies!
window.DeliveryMethodCollection = DeliveryMethodCollection;
