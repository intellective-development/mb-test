// @flow

import React, { Component } from 'react';
import uuid from 'uuid';
import { withGoogleMap, GoogleMap, Polygon } from 'react-google-maps';
import getCSRFToken from 'admin/utils/csrf_token';

const GOOGLE_MAP_OPTIONS = {
  backgroundColor: '#fff',
  maxZoom: 17,
  minZoom: 4,
  tilt: 0
};

const ACTIVE_POLYGON_OPTIONS = {
  strokeColor: '#0CC039',
  fillColor: '#3BE36A'
};

const CENTER_LAT = 39.8097343;
const CENTER_LONG = -98.5556199;
const DEFAULT_ZOOM = 4;

const DeliveryZoneMap = withGoogleMap(props => (
  <GoogleMap
    defaultZoom={DEFAULT_ZOOM}
    defaultCenter={new google.maps.LatLng(CENTER_LAT, CENTER_LONG)}
    options={GOOGLE_MAP_OPTIONS}>
    {props.active_polygons.map((polygon, _index) => (
      <Polygon
        key={uuid()}
        options={ACTIVE_POLYGON_OPTIONS}
        path={polygon} />
    ))}
  </GoogleMap>
));

type DeliveryZoneCoveragesProps = {};

const StatusBar = ({status, loading}) => {
  const status_message = loading ? 'Refreshing Polygons' : status;
  return (
    <div className="delivery-zone__status">
      {status_message}
    </div>
  );
};

class DeliveryZoneCoverages extends Component {
  props: DeliveryZoneCoveragesProps
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
      polygons: [],
      status: 'Ready',
      loading: false
    };
  }
  componentDidMount(){
    this._fetchPolygons();
  }
  _fetchPolygons(){
    const self = this;
    self.setState({loading: true});

    fetch('/admin/delivery_coverages/get_active_delivery_zones_polygons', {
      ...DeliveryZoneCoverages.requestHeaders()
    }).then(response => response.json())
      .then(data => {
        self.setState({polygons: data, loading: false});
      });
  }
  render(){
    return (
      <div>
        <DeliveryZoneMap
          googleMapURL="https://maps.googleapis.com/maps/api/js?v=3.exp&libraries=geometry,places"
          loadingElement={<div style={{ height: '100%' }} />}
          containerElement={
            <div style={{ width: '100%', height: '500px' }} />
          }
          mapElement={
            <div style={{ width: '100%', height: '100%' }} />
          }
          active_polygons={this.state.polygons} />
        <StatusBar status={this.state.status} loading={this.state.loading} />
      </div>
    );
  }
}

export default DeliveryZoneCoverages;
