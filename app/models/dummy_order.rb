# frozen_string_literal: true

class DummyOrder
  def as_object
    {
      number: '1234567890',
      created_at: DateTime.current.iso8601,
      customer_name: 'John Doe',
      shipments: mocked_shipments,
      video_gift_message: mocked_vgm,
      gift_options: mocked_gift_options,
      is_gift: true
    }
  end

  private

  def mocked_shipments
    [
      {
        state: 'en_route',
        supplier: mocked_supplier,
        order_items: mocked_order_items,
        packages: mocked_packages
      }
    ]
  end

  def mocked_supplier
    {
      name: 'Max Supplier'
    }
  end

  def mocked_order_items
    [
      {
        name: 'Order item 1',
        quantity: 1,
        image_url: 'https://placeholder.pics/svg/100'
      },
      {
        name: 'Order item 2',
        quantity: 1,
        image_url: 'https://placeholder.pics/svg/100'
      }
    ]
  end

  def mocked_packages
    [
      {
        tracking_number: 'TN12345ABC',
        carrier: 'fedex',
        state: 'en_route',
        expected_delivery_date: (Date.current + 1.day).to_datetime.iso8601
      },
      {
        tracking_number: 'TN54321CBA',
        carrier: 'ups',
        state: 'delivered',
        expected_delivery_date: Date.current.to_datetime.iso8601
      }
    ]
  end

  def mocked_vgm
    {
      watch_video_url: 'https://placeholder.pics/svg/100'
    }
  end

  def mocked_gift_options
    {
      message: 'Happy Birthday!',
      recipient_name: 'Johnny Recipient'
    }
  end
end
