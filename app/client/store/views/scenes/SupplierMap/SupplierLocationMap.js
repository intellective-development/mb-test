// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { withGoogleMap, GoogleMap, Marker } from 'react-google-maps';
import { address_helpers } from 'store/business/address';
import { delivery_method_constants } from 'store/business/delivery_method';
import { supplier_helpers } from 'store/business/supplier';
import type { Supplier } from 'store/business/supplier';

import { MBText } from '../../elements';

const GOOGLE_MAP_OPTIONS = {
  backgroundColor: '#fff',
  clickableIcons: false,
  disableDefaultUI: true,
  maxZoom: 20,
  minZoom: 10,
  scaleControl: true,
  tilt: 0
};

type SupplierLocationMapProps = {supplier: Supplier};
const SupplierLocationMap = ({supplier}: SupplierLocationMapProps) => {
  if (!supplier) return null;

  return (
    <div>
      <SupplierLocation supplier={supplier} />
      <SupplierMap
        supplier={supplier}
        containerElement={<div className="sm__map__container" />}
        mapElement={<div className="sm__map__container" />} />
    </div>
  );
};

const SupplierLocation = ({supplier}) => {
  const has_pickup = supplier.delivery_methods.some(dm => dm.type === delivery_method_constants.PICKUP);

  return (
    <div className="sm__header__container">
      <MBText.H4 className="sm__header__name">{supplier.name}</MBText.H4>
      <MBText.H5 className="sm__header__location">
        {address_helpers.formatStreetAndCity(supplier.address)}
        <SupplierDistance supplier={supplier} is_hidden={!has_pickup} />
      </MBText.H5>
    </div>
  );
};

const SupplierDistance = ({supplier, is_hidden}) => {
  if (is_hidden) return null;

  return (
    <MBText.Span>
      ・{supplier_helpers.formatDistance(supplier)}
    </MBText.Span>
  );
};

const SupplierMap = withGoogleMap(({supplier}) => {
  const supplier_lat_lng = new google.maps.LatLng(supplier.address.latitude, supplier.address.longitude);

  return (
    <GoogleMap
      defaultZoom={17}
      defaultCenter={supplier_lat_lng}
      options={GOOGLE_MAP_OPTIONS}>
      <Marker position={supplier_lat_lng} />
    </GoogleMap>
  );
});

const SupplierLocationMapSTP = () => {
  const findSupplier = Ent.query(Ent.find('supplier'), Ent.join('delivery_methods'));

  return (state, {supplier_id}) => ({
    supplier: findSupplier(state, supplier_id)
  });
};
const SupplierLocationMapContainer = connect(SupplierLocationMapSTP)(SupplierLocationMap);

export default SupplierLocationMapContainer;
