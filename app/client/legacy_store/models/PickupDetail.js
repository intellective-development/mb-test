import { BackboneRXModel } from 'shared/utils/backbone_rx';

const PickupDetail = BackboneRXModel.extend({
  initialize(){
    this.listenTo(User, 'user:pickup_detail_added', this.associatePickupDetail);
  },

  associatePickupDetail(data){
    this.clear({silent: true}).set(data, {silent: true});
    this.trigger('pickup_detail:saved');
  },

  isLocal(){
    return !this.get('id');
  },

  formattedPhoneNumber: function(){ // 1 external
    // This is a much larger kettle of fish than this, but for now we'll just assume we have a
    // US phone number without symbols, dashes and such; and attempt to format it.
    var phone = this.get('phone');
    if (phone && phone.length == 12){
      // note that this phone number is returned from the server like "+19876543210"
      return phone.replace(/\+1(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
    } else {
      return phone;
    }
  },

  validate(){}
});

export default PickupDetail;

//TODO: remove! use real dependencies!
window.PickupDetail = PickupDetail;
