defmodule DelhiDarwaza.OrderBookSnapshotTest do
  use ExUnit.Case, async: true

  alias DelhiDarwaza.Order
  alias DelhiDarwaza.OrderBook
  alias DelhiDarwaza.OrderBookSnapshot

  describe "from_order_book/1" do
    test "creates a snapshot from an order book" do
      book = OrderBook.new("BTC/USD")

      bid =
        Order.new(
          "bid_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("49000"),
          Decimal.new("1")
        )

      ask =
        Order.new(
          "ask_1",
          "user_1",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("51000"),
          Decimal.new("2")
        )

      book =
        book
        |> OrderBook.add_order(bid)
        |> OrderBook.add_order(ask)

      snapshot = OrderBookSnapshot.from_order_book(book)

      assert snapshot.symbol == "BTC/USD"
      assert length(snapshot.bids) == 1
      assert length(snapshot.asks) == 1
      assert hd(snapshot.bids).price |> Decimal.equal?(Decimal.new("49000"))
      assert hd(snapshot.asks).price |> Decimal.equal?(Decimal.new("51000"))
      refute is_nil(snapshot.timestamp)
    end

    test "aggregates quantity at each price level" do
      book = OrderBook.new("BTC/USD")

      order1 =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      order2 =
        Order.new(
          "order_2",
          "user_2",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("2")
        )

      book =
        book
        |> OrderBook.add_order(order1)
        |> OrderBook.add_order(order2)

      snapshot = OrderBookSnapshot.from_order_book(book)

      assert length(snapshot.bids) == 1
      level = hd(snapshot.bids)
      assert Decimal.equal?(level.quantity, Decimal.new("3"))
      assert level.order_count == 2
    end
  end

  describe "from_order_book/2" do
    test "limits depth to max_depth levels" do
      book = OrderBook.new("BTC/USD")

      orders = [
        Order.new(
          "bid_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        ),
        Order.new(
          "bid_2",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("49000"),
          Decimal.new("1")
        ),
        Order.new(
          "bid_3",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("48000"),
          Decimal.new("1")
        )
      ]

      book = Enum.reduce(orders, book, &OrderBook.add_order(&2, &1))

      snapshot = OrderBookSnapshot.from_order_book(book, 2)

      assert length(snapshot.bids) == 2
    end
  end
end
