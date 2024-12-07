// @flow
// This file is a pile of hacks and HOCs to repurpose content-layout work for a non-content-layout.
// The main pain point is getting a content_url returned from the server with only one supplier,
// which would require reworking what could be passed through as ContentLayout context.
// It is a low priority feature ATM, so probably not worth rewriting until it breaks
import * as React from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { buildMBApiUrl } from '@minibar/store-business/src/networking/mb_api_helpers';
import { withUniqueId } from 'store/views/elements';
import * as shipment_helpers from 'legacy_store/models/Shipment';
import connectProductScroller from 'store/views/compounds/ProductScroller/ConnectProductScroller';
import MeetMinimumPanel from 'cart/shipment_panel/meet_minimum_panel';

type MeetMinimumProductLoaderProps = {
  cart_meet_min_id: string,
  supplier_id: string,
  shipment: object,
};

const MeetMinimumProductScroller = connectProductScroller(MeetMinimumPanel);
const CartMeetMinimumProductLoader = ({ cart_meet_min_id, content_module, shipment, supplier_id }: MeetMinimumProductLoaderProps) => {
  const amount_below_minimum = shipment_helpers.shipmentMinimumDifference(shipment);

  if (amount_below_minimum <= 0) return null;

  const content_url = buildMBApiUrl('supplier/:supplier_id/related', {
    supplier_id,
    product_grouping_ids: shipment.items.map(item => item.product_grouping.id),
    price: { min: amount_below_minimum, max: 20 }
  });

  return (
    <tr>
      <MeetMinimumProductScroller
        content_module_id={cart_meet_min_id}
        product_ids={content_module.products}
        shipment={shipment}
        content_url={content_url} />
    </tr>
  );
};

const CartMeetMinimumProductLoaderSTP = () => {
  const findContentModule = Ent.find('content_module');

  return (state, { cart_meet_min_id }) => ({
    content_module: findContentModule(state, cart_meet_min_id) || {}
  });
};

export default withUniqueId('cart_meet_min_id')(connect(CartMeetMinimumProductLoaderSTP)(CartMeetMinimumProductLoader));
