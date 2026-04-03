defmodule DelhiDarwaza.OrderTest do
  @moduledoc """
  Tests for the DelhiDarwaza.Order module.
  """

  use ExUnit.Case
  alias DelhiDarwaza.Order
  import Decimal

  describe "enums" do
    test "valid_side?/1 validates order sides" do
      assert Order.valid_side?(:buy) == true
      assert Order.valid_side?(:sell) == true
      assert Order.valid_side?(:invalid) == false
      assert Order.valid_side?(:BUY) == false
    end

    test "valid_type?/1 validates order types" do
      assert Order.valid_type?(:market) == true
      assert Order.valid_type?(:limit) == true
      assert Order.valid_type?(:stop) == true
      assert Order.valid_type?(:stop_limit) == true
      assert Order.valid_type?(:invalid) == false
    end

    test "valid_status?/1 validates order statuses" do
      assert Order.valid_status?(:pending) == true
      assert Order.valid_status?(:active) == true
      assert Order.valid_status?(:filled) == true
      assert Order.valid_status?(:partially_filled) == true
      assert Order.valid_status?(:cancelled) == true
      assert Order.valid_status?(:rejected) == true
      assert Order.valid_status?(:invalid) == false
    end
  end

  describe "new/7" do
    test "creates a new order with all required fields" do
      order = Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))

      assert order.id == "order_1"
      assert order.user_id == "user_1"
      assert order.symbol == "BTC/USD"
      assert order.side == :buy
      assert order.type == :limit
      assert order.price == new("50000")
      assert order.quantity == new("0.5")
      assert order.status == :pending
      assert order.filled_quantity == new("0")
      assert %DateTime{} = order.timestamp
      assert %DateTime{} = order.created_at
      assert %DateTime{} = order.updated_at
    end

    test "creates market order with nil price" do
      order = Order.new("order_2", "user_1", "BTC/USD", :sell, :market, nil, new("1.0"))

      assert order.type == :market
      assert order.price == nil
    end
  end

  describe "validate/1" do
    test "validates a correct order" do
      order = Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
      assert Order.validate(order) == :ok
    end

    test "rejects invalid order side" do
      order = %Order{
        Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
        | side: :invalid
      }

      assert {:error, _} = Order.validate(order)
    end

    test "rejects invalid order type" do
      order = %Order{
        Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
        | type: :invalid
      }

      assert {:error, _} = Order.validate(order)
    end

    test "rejects limit order without price" do
      order = Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, nil, new("0.5"))
      assert {:error, "Limit orders must have a price"} = Order.validate(order)
    end

    test "rejects stop-limit order without price" do
      order = Order.new("order_1", "user_1", "BTC/USD", :buy, :stop_limit, nil, new("0.5"))
      assert {:error, "Stop-limit orders must have a price"} = Order.validate(order)
    end

    test "allows market order without price" do
      order = Order.new("order_1", "user_1", "BTC/USD", :buy, :market, nil, new("0.5"))
      assert :ok = Order.validate(order)
    end

    test "rejects zero or negative quantity" do
      order1 = Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0"))
      assert {:error, "Quantity must be positive"} = Order.validate(order1)

      order2 = Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("-0.5"))
      assert {:error, "Quantity must be positive"} = Order.validate(order2)
    end

    test "rejects negative filled quantity" do
      order = %Order{
        Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
        | filled_quantity: new("-0.1")
      }

      assert {:error, "Filled quantity cannot be negative"} = Order.validate(order)
    end

    test "rejects filled quantity exceeding order quantity" do
      order = %Order{
        Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
        | filled_quantity: new("1.0")
      }

      assert {:error, "Filled quantity cannot exceed order quantity"} = Order.validate(order)
    end
  end

  describe "buy?/1 and sell?/1" do
    test "buy?/1 identifies buy orders" do
      buy_order =
        Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))

      sell_order =
        Order.new("order_2", "user_1", "BTC/USD", :sell, :limit, new("50000"), new("0.5"))

      assert Order.buy?(buy_order) == true
      assert Order.buy?(sell_order) == false
    end

    test "sell?/1 identifies sell orders" do
      buy_order =
        Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))

      sell_order =
        Order.new("order_2", "user_1", "BTC/USD", :sell, :limit, new("50000"), new("0.5"))

      assert Order.sell?(sell_order) == true
      assert Order.sell?(buy_order) == false
    end
  end

  describe "filled?/1" do
    test "returns true for orders with status :filled" do
      order = %Order{
        Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
        | status: :filled
      }

      assert Order.filled?(order) == true
    end

    test "returns true when filled_quantity equals quantity" do
      order = %Order{
        Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
        | filled_quantity: new("0.5")
      }

      assert Order.filled?(order) == true
    end

    test "returns false for partially filled orders" do
      order = %Order{
        Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
        | filled_quantity: new("0.3")
      }

      assert Order.filled?(order) == false
    end
  end

  describe "active?/1" do
    test "returns true for active order statuses" do
      assert Order.active?(%Order{
               Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
               | status: :pending
             }) == true

      assert Order.active?(%Order{
               Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
               | status: :active
             }) == true

      assert Order.active?(%Order{
               Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
               | status: :partially_filled
             }) == true
    end

    test "returns false for inactive order statuses" do
      assert Order.active?(%Order{
               Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
               | status: :filled
             }) == false

      assert Order.active?(%Order{
               Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
               | status: :cancelled
             }) == false

      assert Order.active?(%Order{
               Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
               | status: :rejected
             }) == false
    end
  end

  describe "cancellable?/1" do
    test "returns true for cancellable order statuses" do
      assert Order.cancellable?(%Order{
               Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
               | status: :pending
             }) == true

      assert Order.cancellable?(%Order{
               Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
               | status: :active
             }) == true

      assert Order.cancellable?(%Order{
               Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
               | status: :partially_filled
             }) == true
    end

    test "returns false for non-cancellable order statuses" do
      assert Order.cancellable?(%Order{
               Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
               | status: :filled
             }) == false

      assert Order.cancellable?(%Order{
               Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
               | status: :cancelled
             }) == false

      assert Order.cancellable?(%Order{
               Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
               | status: :rejected
             }) == false
    end
  end

  describe "update_status/2" do
    test "updates order status and updated_at timestamp" do
      order = Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
      Process.sleep(2)
      updated = Order.update_status(order, :active)

      assert updated.status == :active
      assert DateTime.compare(updated.updated_at, order.updated_at) == :gt
    end
  end

  describe "update_filled_quantity/2" do
    test "updates filled quantity and sets status to filled when complete" do
      order = Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
      updated = Order.update_filled_quantity(order, new("0.5"))

      assert updated.filled_quantity == new("0.5")
      assert updated.status == :filled
    end

    test "updates filled quantity and sets status to partially_filled" do
      order = Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
      updated = Order.update_filled_quantity(order, new("0.3"))

      assert updated.filled_quantity == new("0.3")
      assert updated.status == :partially_filled
    end

    test "keeps original status when filled quantity is zero" do
      order = %Order{
        Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, new("50000"), new("0.5"))
        | status: :active
      }

      updated = Order.update_filled_quantity(order, new("0"))

      assert updated.filled_quantity == new("0")
      assert updated.status == :active
    end
  end
end
