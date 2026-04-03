defmodule DelhiDarwaza.OrderBookTest do
  use ExUnit.Case, async: true

  alias DelhiDarwaza.Order
  alias DelhiDarwaza.OrderBook

  describe "new/1" do
    test "creates an empty order book with the given symbol" do
      book = OrderBook.new("BTC/USD")
      assert book.symbol == "BTC/USD"
      assert OrderBook.empty?(book)
    end
  end

  describe "add_order/2" do
    test "adds a buy order to bids" do
      book = OrderBook.new("BTC/USD")

      order =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, order)

      assert OrderBook.best_bid(book).id == "order_1"
      refute OrderBook.empty?(book)
    end

    test "adds a sell order to asks" do
      book = OrderBook.new("BTC/USD")

      order =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, order)

      assert OrderBook.best_ask(book).id == "order_1"
    end

    test "sorts bids by price descending" do
      book = OrderBook.new("BTC/USD")

      order1 =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("49000"),
          Decimal.new("1")
        )

      order2 =
        Order.new(
          "order_2",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("51000"),
          Decimal.new("1")
        )

      order3 =
        Order.new(
          "order_3",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      book =
        book
        |> OrderBook.add_order(order1)
        |> OrderBook.add_order(order2)
        |> OrderBook.add_order(order3)

      [first, second, third] = book.bids
      assert first.price |> Decimal.equal?(Decimal.new("51000"))
      assert second.price |> Decimal.equal?(Decimal.new("50000"))
      assert third.price |> Decimal.equal?(Decimal.new("49000"))
    end

    test "sorts asks by price ascending" do
      book = OrderBook.new("BTC/USD")

      order1 =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("51000"),
          Decimal.new("1")
        )

      order2 =
        Order.new(
          "order_2",
          "user_1",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("49000"),
          Decimal.new("1")
        )

      order3 =
        Order.new(
          "order_3",
          "user_1",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      book =
        book
        |> OrderBook.add_order(order1)
        |> OrderBook.add_order(order2)
        |> OrderBook.add_order(order3)

      [first, second, third] = book.asks
      assert first.price |> Decimal.equal?(Decimal.new("49000"))
      assert second.price |> Decimal.equal?(Decimal.new("50000"))
      assert third.price |> Decimal.equal?(Decimal.new("51000"))
    end

    test "groups orders at the same price level" do
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

      assert length(book.bids) == 1
      assert length(hd(book.bids).orders) == 2
    end
  end

  describe "remove_order/2" do
    test "removes an existing order" do
      book = OrderBook.new("BTC/USD")

      order =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, order)
      {:ok, book} = OrderBook.remove_order(book, "order_1")

      assert is_nil(OrderBook.get_order(book, "order_1"))
      assert OrderBook.empty?(book)
    end

    test "returns error for non-existent order" do
      book = OrderBook.new("BTC/USD")
      assert {:error, _} = OrderBook.remove_order(book, "nonexistent")
    end

    test "removes price level when last order is removed" do
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
          Decimal.new("49000"),
          Decimal.new("1")
        )

      book =
        book
        |> OrderBook.add_order(order1)
        |> OrderBook.add_order(order2)

      {:ok, book} = OrderBook.remove_order(book, "order_1")
      assert length(book.bids) == 1
    end
  end

  describe "update_order/2" do
    test "updates an existing order" do
      book = OrderBook.new("BTC/USD")

      order =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, order)

      updated_order = %{order | price: Decimal.new("52000")}
      {:ok, book} = OrderBook.update_order(book, updated_order)

      assert OrderBook.get_order(book, "order_1").price |> Decimal.equal?(Decimal.new("52000"))
    end

    test "returns error for non-existent order" do
      book = OrderBook.new("BTC/USD")

      order =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      assert {:error, _} = OrderBook.update_order(book, order)
    end
  end

  describe "get_order/2" do
    test "returns the order if it exists" do
      book = OrderBook.new("BTC/USD")

      order =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, order)

      assert OrderBook.get_order(book, "order_1") == order
    end

    test "returns nil for non-existent order" do
      book = OrderBook.new("BTC/USD")
      assert is_nil(OrderBook.get_order(book, "nonexistent"))
    end
  end

  describe "best_bid/1" do
    test "returns the highest priced bid" do
      book = OrderBook.new("BTC/USD")

      order1 =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("49000"),
          Decimal.new("1")
        )

      order2 =
        Order.new(
          "order_2",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("51000"),
          Decimal.new("1")
        )

      book =
        book
        |> OrderBook.add_order(order1)
        |> OrderBook.add_order(order2)

      assert OrderBook.best_bid(book).id == "order_2"
    end

    test "returns nil when no bids" do
      book = OrderBook.new("BTC/USD")
      assert is_nil(OrderBook.best_bid(book))
    end
  end

  describe "best_ask/1" do
    test "returns the lowest priced ask" do
      book = OrderBook.new("BTC/USD")

      order1 =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("51000"),
          Decimal.new("1")
        )

      order2 =
        Order.new(
          "order_2",
          "user_1",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("49000"),
          Decimal.new("1")
        )

      book =
        book
        |> OrderBook.add_order(order1)
        |> OrderBook.add_order(order2)

      assert OrderBook.best_ask(book).id == "order_2"
    end

    test "returns nil when no asks" do
      book = OrderBook.new("BTC/USD")
      assert is_nil(OrderBook.best_ask(book))
    end
  end

  describe "spread/1" do
    test "returns the difference between best ask and best bid" do
      book = OrderBook.new("BTC/USD")

      bid =
        Order.new(
          "bid_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("49900"),
          Decimal.new("1")
        )

      ask =
        Order.new(
          "ask_1",
          "user_1",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50100"),
          Decimal.new("1")
        )

      book =
        book
        |> OrderBook.add_order(bid)
        |> OrderBook.add_order(ask)

      spread = OrderBook.spread(book)
      assert Decimal.equal?(spread, Decimal.new("200"))
    end

    test "returns nil when either side is empty" do
      book = OrderBook.new("BTC/USD")

      bid =
        Order.new(
          "bid_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("49900"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, bid)

      assert is_nil(OrderBook.spread(book))
    end
  end

  describe "depth/1" do
    test "returns the count of orders on each side" do
      book = OrderBook.new("BTC/USD")

      bid1 =
        Order.new(
          "bid_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      bid2 =
        Order.new(
          "bid_2",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("49000"),
          Decimal.new("1")
        )

      ask1 =
        Order.new(
          "ask_1",
          "user_1",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("51000"),
          Decimal.new("1")
        )

      book =
        book
        |> OrderBook.add_order(bid1)
        |> OrderBook.add_order(bid2)
        |> OrderBook.add_order(ask1)

      depth = OrderBook.depth(book)
      assert depth.bid_count == 2
      assert depth.ask_count == 1
    end
  end

  describe "empty?/1" do
    test "returns true for a new order book" do
      book = OrderBook.new("BTC/USD")
      assert OrderBook.empty?(book)
    end

    test "returns false when orders exist" do
      book = OrderBook.new("BTC/USD")

      order =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, order)
      refute OrderBook.empty?(book)
    end
  end
end
