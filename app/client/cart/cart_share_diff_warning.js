import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { ui_actions, ui_selectors } from 'store/business/ui';

const mapStateToProps = (state) => ({ removed_share_items: ui_selectors.getCartShareDiff(state) });
const mapDispatchToProps = {dismissCartShareDiff: ui_actions.dismissCartShareDiff};
const CartShareDiffWarning = connect(
  mapStateToProps,
  mapDispatchToProps
)(({removed_share_items, dismissCartShareDiff}) => {
  if (_.isEmpty(removed_share_items)) return null;

  return (
    <div className="cart-warning__container branding">
      <a className="cart-warning__close" href="#" onClick={dismissCartShareDiff}>×</a>
      <p className="cart-warning__title">
        <strong>The following items were removed from your cart because they are not currently available from your local stores:</strong>
      </p>
      <ul className="cart-warning__error-list">
        {removed_share_items.map(i => (
          <li className="cart-warning__error-list__item" key={i.variant.id}>
            {i.product_grouping.name} ({i.variant.volume})
          </li>
        ))}
      </ul>
    </div>
  );
});

export default CartShareDiffWarning;
