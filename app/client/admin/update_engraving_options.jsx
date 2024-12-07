import React, { Component, createContext } from 'react';
import StaticSelect from 'admin/select_components/static_select';
import getCSRFToken from 'admin/utils/csrf_token';

const UpdateEngravingOptionsContext = createContext();

export default class UpdateEngravingOptions extends Component {
  static requestHeaders(){
    return {
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': getCSRFToken()
      }
    };
  }

  constructor(props){
    super(props);

    const {order_items} = props;
    const selectedOrdemItemId = order_items[0].id;
    const selectedOrdemItemText = `${order_items[0].item_options.line1} | ${order_items[0].item_options.line2} | ${order_items[0].item_options.line3} | ${order_items[0].item_options.line4}`;
    const selectedOrdemItemShipmentId = order_items[0].shipment_id;
    this.state = {
      orderItems: order_items,
      orderItemsOptions: order_items.map(oi => ({label: oi.variant.name, value: oi.id, shipmentId: oi.shipment_id, text: `${oi.item_options.line1} | ${oi.item_options.line2} | ${oi.item_options.line3} | ${oi.item_options.line4}`})),
      selectedOrdemItemId,
      selectedOrdemItemText,
      selectedOrdemItemShipmentId
    };
  }

  orderItemChange = (orderItem) => {
    console.log('orderItemChange', orderItem);
    const { value, text, shipmentId } = orderItem;
    this.setState({
      selectedOrdemItemId: value,
      selectedOrdemItemText: text,
      selectedOrdemItemShipmentId: shipmentId
    });
  };

  handleTextChange = (event) => {
    this.setState({
      selectedOrdemItemText: event.target.value
    });
  }

  updateText = () => {
    const self = this;
    const { selectedOrdemItemId, selectedOrdemItemText, selectedOrdemItemShipmentId } = self.state;
    if (selectedOrdemItemText.indexOf(' | ') === -1){
      self.setState({error: '" | " is required to identify the first and second lines.'});
      return;
    }
    self.setState({loading: true});

    fetch(`/admin/fulfillment/shipments/${selectedOrdemItemShipmentId}/update_engraving_options`, {
      ...UpdateEngravingOptions.requestHeaders(),
      body: JSON.stringify({
        order_item_id: selectedOrdemItemId,
        line1: selectedOrdemItemText.split(' | ')[0],
        line2: selectedOrdemItemText.split(' | ')[1],
        line3: selectedOrdemItemText.split(' | ')[2],
        line4: selectedOrdemItemText.split(' | ')[3]
      }),
      method: 'PUT'
    }).then(() => {
      self.setState({loading: false});
    })
      .catch(error => console.error(error));
  }

  render(){
    const { orderItemsOptions, selectedOrdemItemId, selectedOrdemItemText, loading, error } = this.state;
    return (
      <UpdateEngravingOptionsContext.Provider value={{orderItemChange: this.orderItemChange}}>
        <div className="row order">
          <div className="large-12 column" style={{marginBottom: 20}}>
            <StaticSelect
              options={orderItemsOptions}
              initialValueIds={[selectedOrdemItemId]}
              selectedValues={[selectedOrdemItemId]}
              onChange={this.orderItemChange}
              name="order_item"
              label="" />
          </div>
          <div className="large-12 column" style={{marginBottom: 20}}>
            <textarea
              value={selectedOrdemItemText}
              onChange={this.handleTextChange} />
          </div>
          <div className="large-12 column">
            {error && <p className="error">{error}</p>}
            <button disabled={loading} onClick={this.updateText}>{loading ? 'Updating...' : 'Update' }</button>
          </div>
        </div>
      </UpdateEngravingOptionsContext.Provider>
    );
  }
}
