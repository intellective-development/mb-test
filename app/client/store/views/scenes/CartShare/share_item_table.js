import * as React from 'react';
import ItemSummary from 'cart/shipment_panel/item_summary';

const ShareItemTable = ({items = []}) => {
  const item_rows = items.map(item => (
    <ItemSummary item={item} key={item.variant.id} />
  ));

  return (
    <table className="shipment-table shipment-table--anonymous"><tbody>
      {item_rows}
    </tbody></table>
  );
};

export default ShareItemTable;
