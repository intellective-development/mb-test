// @flow

import React, { Component } from 'react';
import _ from 'lodash';
import uuid from 'uuid';
import { withGoogleMap, GoogleMap, Marker, Polygon } from 'react-google-maps';
import DrawingManager from 'react-google-maps/lib/components/drawing/DrawingManager';
import getCSRFToken from 'admin/utils/csrf_token';
import measureDistanceInMiles from 'admin/utils/geo';

const GOOGLE_MAP_OPTIONS = {
  backgroundColor: '#fff',
  clickableIcons: false,
  disableDefaultUI: true,
  maxZoom: 17,
  minZoom: 4,
  scaleControl: true,
  tilt: 0
};

const ACTIVE_POLYGON_OPTIONS = {
  strokeColor: '#0CC039',
  fillColor: '#3BE36A'
};

const INACTIVE_POLYGON_OPTIONS = {
  strokeColor: '#D60060',
  fillColor: '#EA2688'
};

const STATES = [
  ['Alabama', 'AL'], ['Alaska', 'AK'], ['Arizona', 'AZ'], ['Arkansas', 'AR'], ['California', 'CA'], ['Colorado', 'CO'], ['Connecticut', 'CT'], ['Delaware', 'DE'], ['District of Colombia', 'DC'], ['Florida', 'FL'], ['Georgia', 'GA'], ['Hawaii', 'HI'], ['Idaho', 'ID'], ['Illinois', 'IL'], ['Indiana', 'IN'], ['Iowa', 'IA'], ['Kansas', 'KS'], ['Kentucky', 'KY'], ['Louisiana', 'LA'], ['Maine', 'ME'], ['Maryland', 'MD'], ['Massachusetts', 'MA'], ['Michigan', 'MI'], ['Minnesota', 'MN'], ['Mississippi', 'MS'], ['Missouri', 'MO'], ['Montana', 'MT'], ['Nebraska', 'NE'], ['Nevada', 'NV'], ['New Hampshire', 'NH'], ['New Jersey', 'NJ'], ['New Mexico', 'NM'], ['New York', 'NY'], ['North Carolina', 'NC'], ['North Dakota', 'ND'], ['Ohio', 'OH'], ['Oklahoma', 'OK'], ['Oregon', 'OR'], ['Pennsylvania', 'PA'], ['Rhode Island', 'RI'], ['South Carolina', 'SC'], ['South Dakota', 'SD'], ['Tennessee', 'TN'], ['Texas', 'TX'], ['Utah', 'UT'], ['Vermont', 'VT'], ['Virginia', 'VA'], ['Washington', 'WA'], ['West Virginia', 'WV'], ['Wisconsin', 'WI'], ['Wyoming', 'WY']
];

const DeliveryZoneMap = withGoogleMap(props => (
  <GoogleMap
    defaultZoom={12}
    defaultCenter={new google.maps.LatLng(props.initialLat, props.initialLng)}
    onMouseMove={props.onMouseMove}
    options={GOOGLE_MAP_OPTIONS}>
    <DrawingManager
      defaultOptions={{
        drawingControl: true,
        drawingControlOptions: {
          position: google.maps.ControlPosition.TOP_RIGHT,
          drawingModes: [
            google.maps.drawing.OverlayType.CIRCLE,
            google.maps.drawing.OverlayType.POLYGON
          ]
        }
      }}
      onCircleComplete={props.onCircleComplete}
      onPolygonComplete={props.onPolygonComplete} />
    <Marker position={new google.maps.LatLng(props.initialLat, props.initialLng)} />
    {props.active_polygons.map((polygon, _index) => (
      <Polygon
        key={uuid()}
        options={ACTIVE_POLYGON_OPTIONS}
        onMouseOver={() => { props.updateStatus(`Selected Zone ${polygon[0].id} (Active)`); }}
        onMouseOut={() => { props.updateStatus(''); }}
        onMouseMove={props.onMouseMove}
        path={polygon} />
    ))}
    {props.inactive_polygons.map((polygon, _index) => (
      <Polygon
        key={uuid()}
        options={INACTIVE_POLYGON_OPTIONS}
        onMouseOver={() => { props.updateStatus(`Selected Zone ${polygon[0].id} (Inactive)`); }}
        onMouseOut={() => { props.updateStatus(''); }}
        onMouseMove={props.onMouseMove}
        path={polygon} />
    ))}
  </GoogleMap>
));

const DeliveryZoneListColumn = ({title, data, onToggleState, onTogglePriority, onDestroy}) => (
  <div className="medium-6 column">
    <h4>{title} ({data.length})</h4>
    <ul>
      {data.map(delivery_zone => (
        <DeliveryZoneListItem
          key={delivery_zone[0].id}
          delivery_zone={delivery_zone}
          onDestroy={() => {
            onDestroy(delivery_zone[0].id);
          }}
          onTogglePriority={() => {
            onTogglePriority(delivery_zone[0].id);
          }}
          onToggleState={() => {
            onToggleState(delivery_zone[0].id);
          }} />
      ))}
    </ul>
  </div>
);

const DeliveryZoneListItem = ({delivery_zone, onToggleState, onTogglePriority, onDestroy}) => (
  <li>
    {delivery_zone[0].priority ? 'Priority' : null} Zone <small>ID {delivery_zone[0].id}</small>
    <br />
    <small>
      <a role="presentation" onClick={onToggleState}>Toggle State</a> | <a role="presentation" onClick={onTogglePriority}>Toggle Priority</a> | <a role="presentation" onClick={onDestroy}>Delete</a>
    </small>
  </li>
);

type DeliveryZoneEditorProps = {
  lat: float,
  lng: float,
  shipping_method_id: number,
  supplier_id: number,
  use_delivery_zone_state: boolean
};

const StatusBar = ({status, loading, distance}) => {
  const status_message = loading ? 'Refreshing Polygons' : status;
  return (
    <div className="delivery-zone__status">
      {status_message} &nbsp; &nbsp; {distance} miles from store.
    </div>
  );
};

const DeliveryStateSelect = ({validateState, onClick, onSave}) => {
  return (
    <div>
      <h5>Select eligible states for shipping</h5>
      <ul className="small-block-grid-4">
        {STATES.map((state, _index) => (
          <StateCheckbox key={state[1]} name={state[0]} value={state[1]} checked={validateState(state[1])} onClick={onClick} />
        ))}
      </ul>
      <SaveButton label="Save Changes to States" onClick={onSave} />
    </div>
  );
};

const StateCheckbox = ({name, value, checked, onClick}) => (
  <li>
    <label htmlFor={`check-${value}`}>
      <input id={`check-${value}`} type="checkbox" value={value} checked={checked} onClick={onClick} /> {name}
    </label>
  </li>
);

const SaveButton = ({label, onClick}) => (
  <button onClick={onClick} className="button">{label}</button>
);

class DeliveryZoneEditor extends Component {
  props: DeliveryZoneEditorProps
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
    this.state = {
      polygons: {
        active: [],
        inactive: []
      },
      states: [],
      status: 'Ready',
      loading: false
    };
  }
  componentDidMount(){
    this.props.use_delivery_zone_state ? this._fetchStates() : this._fetchPolygons();
  }
  _fetchStates(){
    const self = this;
    self.setState({loading: true});

    fetch(`/admin/inventory/shipping_methods/${this.props.shipping_method_id}/states`, {
      ...DeliveryZoneEditor.requestHeaders()
    }).then(response => response.json())
      .then(data => {
        self.setState({states: data.states, loading: false});
      });
  }
  _fetchPolygons(){
    const self = this;
    self.setState({loading: true});

    fetch(`/admin/inventory/shipping_methods/${this.props.shipping_method_id}/polygons`, {
      ...DeliveryZoneEditor.requestHeaders()
    }).then(response => response.json())
      .then(data => {
        self.setState({polygons: data, loading: false});
      });
  }
  _toggleDeliveryZoneState(zone_id){
    const self = this;
    self.setState({loading: true});

    fetch(`/admin/inventory/shipping_methods/${this.props.shipping_method_id}/activate_delivery_zone?zone=${zone_id}`, {
      ...DeliveryZoneEditor.requestHeaders(),
      method: 'POST'
    }).then(() => self._fetchPolygons())
      .catch(error => console.error(error));
  }
  _toggleDeliveryZonePriority(zone_id){
    const self = this;
    self.setState({loading: true});

    fetch(`/admin/inventory/shipping_methods/${this.props.shipping_method_id}/toggle_priority_delivery_zone?zone=${zone_id}`, {
      ...DeliveryZoneEditor.requestHeaders(),
      method: 'POST'
    }).then(() => self._fetchPolygons())
      .catch(error => console.error(error));
  }
  _destroyDeliveryZone(zone_id){
    const self = this;
    self.setState({loading: true});

    fetch(`/admin/inventory/shipping_methods/${this.props.shipping_method_id}/remove_delivery_zone?zone=${zone_id}`, {
      ...DeliveryZoneEditor.requestHeaders(),
      method: 'POST'
    }).then(() => self._fetchPolygons())
      .catch(error => console.error(error));
  }
  _createDeliveryZone(data){
    const self = this;
    self.setState({loading: true});

    fetch(`/admin/inventory/shipping_methods/${this.props.shipping_method_id}/add_delivery_zone`, {
      ...DeliveryZoneEditor.requestHeaders(),
      method: 'POST',
      body: JSON.stringify(data)
    }).then(() => self._fetchPolygons())
      .catch(error => console.error(error));
  }
  _saveStates(){
    const self = this;
    self.setState({loading: true});

    fetch(`/admin/inventory/shipping_methods/${this.props.shipping_method_id}/update_states`, {
      ...DeliveryZoneEditor.requestHeaders(),
      method: 'POST',
      body: JSON.stringify({
        states: this.state.states
      })
    }).then(() => self._fetchStates())
      .catch(error => console.error(error));
  }
  _updateStatus(status){
    this.setState({status: status});
  }
  _updateDistance(event){
    const distance = measureDistanceInMiles(event.latLng.lat(), event.latLng.lng(), this.props.lat, this.props.lng);
    this.setState({distance});
  }
  _onUpdateStates(event){
    this.setState({states: _.xor(this.state.states, [event.target.value])});
  }
  _onCircleComplete(circle){
    const data = {};

    data.type = 'circle';
    data.radius = circle.getRadius();
    data.center = {
      lat: circle.getCenter().lat(),
      lng: circle.getCenter().lng()
    };

    this._createDeliveryZone(data);
  }
  _onPolygonComplete(polygon){
    const data = {};
    const points = polygon.getPath().getArray();

    data.type = 'polygon';
    data.points = [];

    points.forEach(point => {
      data.points.push({
        lat: point.lat(),
        lng: point.lng()
      });
    });

    this._createDeliveryZone(data);
  }
  _validateState(state){
    return this.state.states.includes(state);
  }
  render(){
    let editor_interface;

    if (this.props.use_delivery_zone_state){
      editor_interface = (
        <DeliveryStateSelect
          onClick={this._onUpdateStates.bind(this)}
          onSave={this._saveStates.bind(this)}
          validateState={this._validateState.bind(this)} />
      );
    } else {
      editor_interface = (
        <div>
          <DeliveryZoneMap
            googleMapURL="https://maps.googleapis.com/maps/api/js?v=3.exp&libraries=geometry,drawing,places"
            loadingElement={<div style={{ height: '100%' }} />}
            containerElement={
              <div style={{ width: '100%', height: '500px' }} />
            }
            mapElement={
              <div style={{ width: '100%', height: '100%' }} />
            }
            initialLat={this.props.lat}
            initialLng={this.props.lng}
            active_polygons={this.state.polygons.active}
            inactive_polygons={this.state.polygons.inactive}
            updateStatus={this._updateStatus.bind(this)}
            onMouseMove={this._updateDistance.bind(this)}
            onCircleComplete={this._onCircleComplete.bind(this)}
            onPolygonComplete={this._onPolygonComplete.bind(this)} />
          <StatusBar status={this.state.status} loading={this.state.loading} distance={this.state.distance} />
          <div className="row">
            <DeliveryZoneListColumn
              title="Active Zones"
              data={this.state.polygons.active}
              onDestroy={this._destroyDeliveryZone.bind(this)}
              onTogglePriority={this._toggleDeliveryZonePriority.bind(this)}
              onToggleState={this._toggleDeliveryZoneState.bind(this)} />
            <DeliveryZoneListColumn
              title="Inactive Zones"
              data={this.state.polygons.inactive}
              onDestroy={this._destroyDeliveryZone.bind(this)}
              onTogglePriority={this._toggleDeliveryZonePriority.bind(this)}
              onToggleState={this._toggleDeliveryZoneState.bind(this)} />
          </div>
        </div>
      );
    }

    return (
      <div>
        {editor_interface}
      </div>
    );
  }
}

export default DeliveryZoneEditor;
