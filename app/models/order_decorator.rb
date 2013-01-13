Order.class_eval do
  belongs_to :self_delivery_point

  attr_accessible :self_delivery_point_id

  spree_has_available_shipment = instance_method(:has_available_shipment)

  before_validation :set_ship_address

  state_machine.before_transition :to => 'delivery' do |order|
    if order.self_delivery? && !order.self_delivery_point
      order.shipping_method = nil
      order.save
    end
  end

  state_machine.after_transition :to => 'delivery' do |order|
    if order.self_delivery?
      order.state = order.payment_required? ? 'payment' : 'complete'
    end
  end

  def self_delivery_point_id=(point_id)
    @self_delivery_point_id = point_id
  end

  def self_delivery?
    shipping_method && shipping_method.self_delivery?
  end

  private

  def set_ship_address
    if @self_delivery_point_id
      write_attribute(:self_delivery_point_id, @self_delivery_point_id)
      return if @self_delivery_point_id.to_i < 1 || !ship_address
      if sdp = SelfDeliveryPoint.find_by_id(@self_delivery_point_id)
        [:country, :state, :city, :address1].each do |a|
          ship_address.send("#{a}=", sdp.send(a))
        end
        ship_address.zipcode = '-'
        self.shipping_method = ShippingMethod.self_delivery
      end
    end 
  end

  define_method :has_available_shipment do
    if self_delivery?
      return
    else
      spree_has_available_shipment.bind(self).call
    end
  end
end