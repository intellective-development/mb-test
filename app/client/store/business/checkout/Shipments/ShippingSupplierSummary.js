import React from 'react';
import { useSelector } from 'react-redux';

import { selectSupplierById } from 'client/modules/supplier/supplier.dux';

const ShippingSupplierSummary = ({ supplierId }) => {
  const supplier = useSelector(selectSupplierById)(supplierId) || {};
  return (
    <div>
      <div>{supplier.name}</div>
    </div>
  );
};

export default ShippingSupplierSummary;
