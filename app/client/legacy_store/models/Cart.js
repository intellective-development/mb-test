import { BackboneRXModel } from 'shared/utils/backbone_rx';

const CHANGED_CART_ACTION_TYPES = [
  'CART_ITEM:ADD',
  'CART_ITEM:REMOVE',
  'CART_ITEM:UPDATE_QUANTITY',
  'CART_ITEM:FETCH_CART__SUCCESS',
  'CART_ITEM:UPDATE_FROM_SHARE__SUCCESS'
];

// model
const Cart = BackboneRXModel.extend({
  initialize: function(){
    this.freezeModel();
    this.store$
      .filter(({action, state}) => CHANGED_CART_ACTION_TYPES.includes(action.type))
      .subscribe((_store) => this.trigger('cart:change')); // this side-effect allows the legacy Order model to stay up to date
  }
});

export default Cart;

//TODO: remove! use real dependencies!
window.Cart = Cart;
