module Coinbase
  module Exchange
    class Orderbook
      PRICE = 0
      SIZE = 1
      ORDER_ID = 2

      attr_accessor :bids, :asks

      def initialize(initial_state)
        @sequence = initial_state['sequence'].to_i
        @bids = initial_state['bids'].map do |bid|
          [BigDecimal.new(bid[PRICE]), BigDecimal.new(bid[SIZE]), bid[ORDER_ID]]
        end
        @asks = initial_state['asks'].map do |ask|
          [BigDecimal.new(ask[PRICE]), BigDecimal.new(ask[SIZE]), ask[ORDER_ID]]
        end
      end

      def open(msg)
        new_record = [BigDecimal.new(msg['price']), BigDecimal.new(msg['remaining_size']), msg['order_id']]

        if (msg['side'] == 'sell')
          insert_order(@asks, lambda { |new_price, old_price| new_price < old_price }, new_record)
        elsif (msg['side'] == 'buy')
          insert_order(@bids, lambda { |new_price, old_price| new_price > old_price }, new_record)
        else
          raise "Invalid side #{msg['side']} for new order"
        end
      end

      def change(msg)
        modification = lambda do |order|
          if order[SIZE] != BigDecimal.new(msg['old_size'])
            raise "Change message received but old_size does not match current size"
          end

          if order[PRICE] != BigDecimal.new(msg['price'])
            raise "Change message received but price does not match current price"
          end

          order[SIZE] = BigDecimal.new(msg['new_size'])
        end

        modify_order(get_side(msg['side']), msg['order_id'], modification)
      end

      def done(msg)
        remove_order(get_side(msg['side']), msg['order_id'])
      end

      def match(msg)
        modification = lambda do |order|
          order[Orderbook::SIZE] -= BigDecimal.new(msg['size'])
        end

        modify_order(get_side(msg['side']), msg['maker_order_id'], modification)
      end

    private

      def get_side(side)
        if (side == 'sell')
          @asks
        elsif (side == 'buy')
          @bids
        else
          raise "Invalid side #{side}"
        end
      end

      def modify_order(side, order_id, modification)
        side.each do |order|
          if order[ORDER_ID] == order_id
            modification.call(order)
          end
        end
      end

      def remove_order(side, order_id)
        side.each_with_index do |order, i|
          if order[ORDER_ID] == order_id
            side.delete_at(i)
            break
          end
        end
      end

      def insert_order(side, comparator, new_record)
        inserted = false
        side.each_with_index do |order, i|
          if comparator.call(new_record[PRICE], order[PRICE])
            side.insert(i, new_record)
            inserted = true
            break
          end
        end
        side.push(new_record) if !inserted
      end
    end
  end
end
