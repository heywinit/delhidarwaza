defmodule DelhiDarwaza.MatchingEngineTest do
  use ExUnit.Case, async: true

  alias DelhiDarwaza.Account
  alias DelhiDarwaza.MatchingEngine
  alias DelhiDarwaza.Order
  alias DelhiDarwaza.OrderBook

  defp setup_accounts do
    %{
      "user_1" =>
        Account.new("user_1")
        |> Account.deposit("USD", Decimal.new("100000"))
        |> Account.deposit("BTC", Decimal.new("10")),
      "user_2" =>
        Account.new("user_2")
        |> Account.deposit("USD", Decimal.new("100000"))
        |> Account.deposit("BTC", Decimal.new("10"))
    }
  end

  describe "match_order/3 - limit buy order" do
    test "fully fills when matching ask exists at or below limit price" do
      book = OrderBook.new("BTC/USD")

      sell_order =
        Order.new(
          "sell_1",
          "user_2",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, sell_order)

      buy_order =
        Order.new(
          "buy_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      accounts = setup_accounts()

      result = MatchingEngine.match_order(buy_order, book, accounts)

      assert length(result.trades) == 1
      trade = hd(result.trades)
      assert Decimal.equal?(trade.price, Decimal.new("50000"))
      assert Decimal.equal?(trade.quantity, Decimal.new("1"))
      assert is_nil(result.remaining_order)
    end

    test "partially fills when ask has less quantity" do
      book = OrderBook.new("BTC/USD")

      sell_order =
        Order.new(
          "sell_1",
          "user_2",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50000"),
          Decimal.new("0.5")
        )

      book = OrderBook.add_order(book, sell_order)

      buy_order =
        Order.new(
          "buy_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      accounts = setup_accounts()

      result = MatchingEngine.match_order(buy_order, book, accounts)

      assert length(result.trades) == 1
      trade = hd(result.trades)
      assert Decimal.equal?(trade.quantity, Decimal.new("0.5"))
      assert result.remaining_order != nil
      assert Decimal.equal?(result.remaining_order.filled_quantity, Decimal.new("0.5"))
    end

    test "does not match when ask price is above limit" do
      book = OrderBook.new("BTC/USD")

      sell_order =
        Order.new(
          "sell_1",
          "user_2",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("51000"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, sell_order)

      buy_order =
        Order.new(
          "buy_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      accounts = setup_accounts()

      result = MatchingEngine.match_order(buy_order, book, accounts)

      assert result.trades == []
      assert result.remaining_order != nil
    end

    test "fills from multiple asks at different prices" do
      book = OrderBook.new("BTC/USD")

      sell1 =
        Order.new(
          "sell_1",
          "user_2",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50000"),
          Decimal.new("0.5")
        )

      sell2 =
        Order.new(
          "sell_2",
          "user_2",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50100"),
          Decimal.new("0.5")
        )

      book = OrderBook.add_order(book, sell1)
      book = OrderBook.add_order(book, sell2)

      buy_order =
        Order.new(
          "buy_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50100"),
          Decimal.new("1")
        )

      accounts = setup_accounts()

      result = MatchingEngine.match_order(buy_order, book, accounts)

      assert length(result.trades) == 2
      [trade1, trade2] = result.trades
      assert Decimal.equal?(trade1.price, Decimal.new("50000"))
      assert Decimal.equal?(trade2.price, Decimal.new("50100"))
      assert is_nil(result.remaining_order)
    end
  end

  describe "match_order/3 - limit sell order" do
    test "fully fills when matching bid exists at or above limit price" do
      book = OrderBook.new("BTC/USD")

      buy_order_resting =
        Order.new(
          "buy_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, buy_order_resting)

      sell_order =
        Order.new(
          "sell_1",
          "user_2",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      accounts = setup_accounts()

      result = MatchingEngine.match_order(sell_order, book, accounts)

      assert length(result.trades) == 1
      trade = hd(result.trades)
      assert Decimal.equal?(trade.price, Decimal.new("50000"))
      assert is_nil(result.remaining_order)
    end

    test "does not match when bid price is below limit" do
      book = OrderBook.new("BTC/USD")

      buy_order_resting =
        Order.new(
          "buy_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("49000"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, buy_order_resting)

      sell_order =
        Order.new(
          "sell_1",
          "user_2",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      accounts = setup_accounts()

      result = MatchingEngine.match_order(sell_order, book, accounts)

      assert result.trades == []
      assert result.remaining_order != nil
    end
  end

  describe "match_order/3 - market buy order" do
    test "fills at best ask price" do
      book = OrderBook.new("BTC/USD")

      sell_order =
        Order.new(
          "sell_1",
          "user_2",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, sell_order)

      buy_order = Order.new("buy_1", "user_1", "BTC/USD", :buy, :market, nil, Decimal.new("1"))
      accounts = setup_accounts()

      result = MatchingEngine.match_order(buy_order, book, accounts)

      assert length(result.trades) == 1
      trade = hd(result.trades)
      assert Decimal.equal?(trade.price, Decimal.new("50000"))
      assert is_nil(result.remaining_order)
    end

    test "sweeps multiple price levels" do
      book = OrderBook.new("BTC/USD")

      sell1 =
        Order.new(
          "sell_1",
          "user_2",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50000"),
          Decimal.new("0.5")
        )

      sell2 =
        Order.new(
          "sell_2",
          "user_2",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("51000"),
          Decimal.new("0.5")
        )

      book = OrderBook.add_order(book, sell1)
      book = OrderBook.add_order(book, sell2)

      buy_order = Order.new("buy_1", "user_1", "BTC/USD", :buy, :market, nil, Decimal.new("1"))
      accounts = setup_accounts()

      result = MatchingEngine.match_order(buy_order, book, accounts)

      assert length(result.trades) == 2
      [trade1, trade2] = result.trades
      assert Decimal.equal?(trade1.price, Decimal.new("50000"))
      assert Decimal.equal?(trade2.price, Decimal.new("51000"))
    end
  end

  describe "match_order/3 - market sell order" do
    test "fills at best bid price" do
      book = OrderBook.new("BTC/USD")

      buy_order_resting =
        Order.new(
          "buy_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, buy_order_resting)

      sell_order = Order.new("sell_1", "user_2", "BTC/USD", :sell, :market, nil, Decimal.new("1"))
      accounts = setup_accounts()

      result = MatchingEngine.match_order(sell_order, book, accounts)

      assert length(result.trades) == 1
      trade = hd(result.trades)
      assert Decimal.equal?(trade.price, Decimal.new("50000"))
    end
  end

  describe "match_order/3 - stop orders" do
    test "stop orders are not matched immediately" do
      book = OrderBook.new("BTC/USD")

      stop_order =
        Order.new(
          "stop_1",
          "user_1",
          "BTC/USD",
          :buy,
          :stop,
          Decimal.new("52000"),
          Decimal.new("1")
        )

      accounts = setup_accounts()

      result = MatchingEngine.match_order(stop_order, book, accounts)

      assert result.trades == []
      assert result.remaining_order != nil
    end

    test "stop-limit orders are not matched immediately" do
      book = OrderBook.new("BTC/USD")

      stop_limit_order =
        Order.new(
          "sl_1",
          "user_1",
          "BTC/USD",
          :buy,
          :stop_limit,
          Decimal.new("52000"),
          Decimal.new("1")
        )

      accounts = setup_accounts()

      result = MatchingEngine.match_order(stop_limit_order, book, accounts)

      assert result.trades == []
      assert result.remaining_order != nil
    end
  end

  describe "match_order/3 - no matching orders" do
    test "returns empty trades and remaining order when book is empty" do
      book = OrderBook.new("BTC/USD")

      buy_order =
        Order.new(
          "buy_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      accounts = setup_accounts()

      result = MatchingEngine.match_order(buy_order, book, accounts)

      assert result.trades == []
      assert result.remaining_order != nil
    end
  end

  describe "match_order/3 - order book state" do
    test "removes fully filled orders from the book" do
      book = OrderBook.new("BTC/USD")

      sell_order =
        Order.new(
          "sell_1",
          "user_2",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      book = OrderBook.add_order(book, sell_order)

      buy_order =
        Order.new(
          "buy_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      accounts = setup_accounts()

      result = MatchingEngine.match_order(buy_order, book, accounts)

      assert OrderBook.empty?(result.order_book)
    end

    test "keeps partially filled orders in the book" do
      book = OrderBook.new("BTC/USD")

      sell_order =
        Order.new(
          "sell_1",
          "user_2",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50000"),
          Decimal.new("2")
        )

      book = OrderBook.add_order(book, sell_order)

      buy_order =
        Order.new(
          "buy_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("50000"),
          Decimal.new("1")
        )

      accounts = setup_accounts()

      result = MatchingEngine.match_order(buy_order, book, accounts)

      refute OrderBook.empty?(result.order_book)
      remaining_ask = OrderBook.best_ask(result.order_book)
      assert remaining_ask != nil
      assert Decimal.equal?(remaining_ask.filled_quantity, Decimal.new("1"))
    end
  end
end
