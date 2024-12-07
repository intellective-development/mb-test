import React from 'react';
import { map, keys } from 'lodash';
import { css } from '@amory/style/umd/style';
import { useDispatch, useSelector } from 'react-redux';
import { selectShipmentsGrouped } from 'modules/cartItem/cartItem.dux';
import {
  SetCheckoutAddressEditing,
  selectCheckoutAddressEditing
} from 'modules/checkout/checkout.dux';
import { EditButton } from '../../shared/EditButton';
import Hr from '../../shared/Hr';
import icon from '../../shared/MBIcon/MBIcon';
import Panel from '../../shared/Panel';
import PanelTitle from '../../shared/PanelTitle';
import { useToggle } from '../../shared/use-toggle';
import styles from '../../Checkout.css.json';
import unstyle from '../../shared/MBElements/MBUnstyle.css.json';
import SupplierSchedule from './SupplierSchedule';

const Scheduling = () => {
  const [toggle, setToggle] = useToggle(true);
  const dispatch = useDispatch();
  const setEditing = editing => dispatch(SetCheckoutAddressEditing(editing));
  const isEditing = useSelector(selectCheckoutAddressEditing);
  const shipments = useSelector(selectShipmentsGrouped);

  return (
    <Panel id="schedule-delivery">
      <div className={css(styles.header)}>
        <PanelTitle id="schedule-delivery" isComplete={!isEditing}>
          Delivery Type
        </PanelTitle>
        {!isEditing && (
          <EditButton onClick={() => setEditing(true)}>Edit</EditButton>
        )}
        <button
          className={css([
            unstyle.button,
            icon({
              name: toggle ? 'arrowDown' : 'arrowUp'
            }),
            styles.paneltoggle
          ])}
          onClick={setToggle}
          type="button" />
      </div>
      <div
        aria-expanded={toggle}
        aria-hidden={!toggle}
        className={css(toggle ? {} : { display: 'none' })}>
        {map(keys(shipments), (supplierId, index) => (
          <React.Fragment>
            {!!index && <Hr />}
            <SupplierSchedule key={supplierId} supplierId={supplierId} />
          </React.Fragment>
        ))}
      </div>
    </Panel>
  );
};

export default Scheduling;
