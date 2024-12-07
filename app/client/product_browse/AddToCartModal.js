import { css } from '@amory/style/umd/style';
import React from 'react';
import { useDispatch, useSelector } from 'react-redux';

import { product_grouping_helpers } from 'store/business/product_grouping';
import { MBModal, MBLink } from 'store/views/elements';
import { ProductBrand, ProductName } from 'store/views/scenes/ProductDetail/ProductDetailElements';
import StoreDeliveryList from 'store/views/scenes/ProductDetail/ProductDetailInternal/StoresDeliveryList';

import { ShowAddToCartModal, selectAddToCartModal } from './product_browse.dux';

const AddToCartModal = () => {
  const dispatch = useDispatch();
  const { modalOpen, product_grouping, variant, supplierCount } = useSelector(selectAddToCartModal);
  const modalReady = !!product_grouping && !!variant;
  const variant_permalink = modalReady ? product_grouping_helpers.fullPermalink(product_grouping, variant) : '';
  const default_variant_permalink = variant_permalink.split('/').pop();
  // If supplierCount < atLeastThreshold, say "{supplierCount} stores", otherwise, say "{atLeastThreshold}+ stores".
  const atLeastThreshold = 3;

  const closeModal = () => dispatch(ShowAddToCartModal({ modalOpen: false }));
  const updateSupplierCount = suppliers => suppliers.length !== supplierCount && dispatch(ShowAddToCartModal({ modalOpen: true, supplierCount: suppliers.length }));
  const addToCardHandler = state => state === 'added' && closeModal();

  return (
    <MBModal.Modal onHide={closeModal} show={modalOpen} size="small">
      <section className={css({ overflowX: 'hidden', padding: '1em' })}>
        <div className={css({ position: 'absolute', right: '1em', top: '1em' })}>
          <MBModal.Close onClick={closeModal} />
        </div>
        {modalReady && (
          <React.Fragment>
            <div className={css({ display: 'flex' })}>
              <img
                className={css({ height: '4em', width: 'auto', marginRight: '16px' })}
                alt={product_grouping.name}
                itemProp="image"
                src={product_grouping_helpers.getImage(product_grouping, variant)} />
              <section className={css({ flexGrow: 1 })}>
                <ProductBrand product_grouping={product_grouping} />
                <ProductName product_grouping={product_grouping} />
              </section>
            </div>

            <StoreDeliveryList
              {...product_grouping}
              default_variant_permalink={default_variant_permalink}
              show={1}
              supplierListCallback={updateSupplierCount}
              addToCardHandler={addToCardHandler} />

            <div className={css({ display: 'flex', marginTop: '1em' })}>
              {supplierCount > 1 && <span>Available at {supplierCount < atLeastThreshold ? supplierCount : `${atLeastThreshold}+`} stores</span>}
              <MBLink.Text className={css({ flexGrow: 1, textAlign: 'right' })} beforeNavigate={closeModal} href={variant_permalink}>
                Full details
              </MBLink.Text>
            </div>
          </React.Fragment>
        )}
      </section>
    </MBModal.Modal>
  );
};

export default AddToCartModal;
