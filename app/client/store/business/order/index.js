// @flow

// TODO: These types are copy/pasted from supplier dashboard, and should be in store-business

export type OrderTags = {
  gift: boolean,
  out_of_hours: boolean,
  vip: boolean,
  corporate: boolean,
  scheduled: boolean,
  new_customer: boolean
};

export type BillingInfo = {
  name: string,
  card_type: string,
  card_last4: string
};

export type Address = {
  address1: string,
  address2: string,
  city: string,
  state: string,
  zip_code: string,
  coords: {lat: number, lng: number}
};

export type PickupDetail = {
  id: string,
  name: string,
  phone: string
};

export type Amounts = {
  total: number,
  subtotal: number,
  tax: number,
  tip: number,
  minibar_promos: number,
  store_discounts: number,
  discounts?: number, // FIXME: optional until sunset
  delivery_fee: number,
};

export type DeliveryMethodType = 'on_demand' | 'shipped' | 'pickup';

export type DeliveryMethod = {
  type: DeliveryMethodType,
  expectation: string
};

export type AttributeFilters = 'vip' | 'gift' | 'scheduled' | 'exception';

export type OrderFilters = {
  date_range: {
    start: string, // iso-8601 timestamp
    end: string // iso-8601 timestamp
  },
  delivery_method_types: Array<DeliveryMethodType>,
  attributes: Array<AttributeFilters>
}

export type RecipientInfo = { short_name: string, long_name: string, phone: string };

export type OrderState = 'paid'
  | 'confirmed'
  | 'scheduled'
  | 'canceled'
  | 'exception'
  | 'en_route'
  | 'delivered';

export type OrderItem = {
  id: number,
  name: string,
  delivery_method: number,
  product_id: string,
  scheduled_for: string,
  volume: string,
  price: string,
  quantity: number
};

export type Order = {
  id: number,
  number: number,
  created_at: string, // rails timestamp
  confirmed_at: string, // rails timestamp
  canceled_at: string, // rails timestamp
  delivered_at: string, // rails timestamp
  scheduled_for: string, // rails timestamp
  scheduled_for_end: string, // rails timestamp
  order_time: string, // rails timestamp
  notes: string,
  delivery_method: DeliveryMethod,
  state: OrderState,
  gift_message: string,
  recipient_info: RecipientInfo,
  customer_name: string,
  billing: BillingInfo,
  birthdate?: string,
  address?: Address,
  pickup_detail?: PickupDetail,
  amounts: Amounts,
  type_tags: OrderTags,
  receipt_url: string,
  order_items: Array<OrderItem>,
  comment_ids: Array<number>, // NOTE: shouldn't be hydrated
  order_adjustment_ids: Array<number>, // NOTE: shouldn't be hydrated
  driver_id: number
};

export * as order_actions from './actions';
export * as order_helpers from './helpers';
