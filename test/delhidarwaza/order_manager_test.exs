defmodule DelhiDarwaza.OrderManagerTest do
  use ExUnit.Case, async: true

  alias DelhiDarwaza.Account
  alias DelhiDarwaza.Order
  alias DelhiDarwaza.OrderBook
  alias DelhiDarwaza.OrderManager

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

  describe "place_order/3 - limit buy" do
    test "places an order that does not match" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

      order =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("40000"),
          Decimal.new("1")
        )

      {:ok, result} = OrderManager.place_order(order, book, accounts)

      assert result.order.status == :active
      assert result.trades == []
      assert not OrderBook.empty?(result.order_book)
    end

    test "places an order and matches immediately" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

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

      {:ok, sell_result} = OrderManager.place_order(sell_order, book, accounts)

      assert sell_result.order.status == :active
      assert not OrderBook.empty?(sell_result.order_book)
      assert OrderBook.get_order(sell_result.order_book, "sell_1") != nil

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

      {:ok, result} =
        OrderManager.place_order(buy_order, sell_result.order_book, sell_result.accounts)

      assert length(result.trades) == 1
      assert result.order.status == :filled
    end

    test "locks funds for a buy order" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

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

      {:ok, result} = OrderManager.place_order(order, book, accounts)

      account = result.accounts["user_1"]
      balance = Account.get_balance(account, "USD")

      assert Decimal.equal?(balance.locked, Decimal.new("50000"))
      assert Decimal.equal?(balance.available, Decimal.new("50000"))
    end

    test "locks BTC for a sell order" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

      order =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :sell,
          :limit,
          Decimal.new("50000"),
          Decimal.new("2")
        )

      {:ok, result} = OrderManager.place_order(order, book, accounts)

      account = result.accounts["user_1"]
      balance = Account.get_balance(account, "BTC")

      assert Decimal.equal?(balance.locked, Decimal.new("2"))
      assert Decimal.equal?(balance.available, Decimal.new("8"))
    end

    test "rejects order with insufficient balance" do
      book = OrderBook.new("BTC/USD")

      accounts = %{
        "user_1" =>
          Account.new("user_1")
          |> Account.deposit("USD", Decimal.new("100"))
      }

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

      assert {:error, _} = OrderManager.place_order(order, book, accounts)
    end

    test "rejects invalid order" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

      order =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          nil,
          Decimal.new("1")
        )

      assert {:error, _} = OrderManager.place_order(order, book, accounts)
    end
  end

  describe "place_order/3 - market buy" do
    test "places a market buy order" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

      order =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :market,
          nil,
          Decimal.new("1")
        )

      {:ok, result} = OrderManager.place_order(order, book, accounts)

      assert result.order.status in [:active, :filled]
    end
  end

  describe "cancel_order/3" do
    test "cancels an active order" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

      order =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("40000"),
          Decimal.new("1")
        )

      {:ok, place_result} = OrderManager.place_order(order, book, accounts)

      {:ok, cancel_result} =
        OrderManager.cancel_order("order_1", place_result.order_book, place_result.accounts)

      assert cancel_result.order.status == :cancelled
      assert OrderBook.empty?(cancel_result.order_book)

      account = cancel_result.accounts["user_1"]
      balance = Account.get_balance(account, "USD")

      assert Decimal.equal?(balance.locked, Decimal.new("0"))
      assert Decimal.equal?(balance.available, Decimal.new("100000"))
    end

    test "returns error for non-existent order" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

      assert {:error, _} = OrderManager.cancel_order("nonexistent", book, accounts)
    end

    test "returns error for already filled order" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

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

      {:ok, sell_result} = OrderManager.place_order(sell_order, book, accounts)

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

      {:ok, result} =
        OrderManager.place_order(buy_order, sell_result.order_book, sell_result.accounts)

      assert {:error, _} = OrderManager.cancel_order("buy_1", result.order_book, result.accounts)
    end

    test "unlocks remaining funds for partially filled order" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

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

      {:ok, sell_result} = OrderManager.place_order(sell_order, book, accounts)

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

      {:ok, result} =
        OrderManager.place_order(buy_order, sell_result.order_book, sell_result.accounts)

      assert result.order.status == :partially_filled

      {:ok, cancel_result} =
        OrderManager.cancel_order("buy_1", result.order_book, result.accounts)

      assert cancel_result.order.status == :cancelled

      account = cancel_result.accounts["user_1"]
      balance = Account.get_balance(account, "USD")

      assert Decimal.equal?(balance.locked, Decimal.new("0"))
    end
  end

  describe "amend_order/4" do
    test "amends order price" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

      order =
        Order.new(
          "order_1",
          "user_1",
          "BTC/USD",
          :buy,
          :limit,
          Decimal.new("40000"),
          Decimal.new("1")
        )

      {:ok, result} = OrderManager.place_order(order, book, accounts)

      {:ok, amend_result} =
        OrderManager.amend_order(
          "order_1",
          [price: Decimal.new("45000")],
          result.order_book,
          result.accounts
        )

      assert amend_result.order.status == :active

      assert OrderBook.get_order(amend_result.order_book, "order_1").price
             |> Decimal.equal?(Decimal.new("45000"))
    end

    test "amends order quantity" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

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

      {:ok, result} = OrderManager.place_order(order, book, accounts)

      {:ok, amend_result} =
        OrderManager.amend_order(
          "order_1",
          [quantity: Decimal.new("2")],
          result.order_book,
          result.accounts
        )

      assert amend_result.order.status == :active

      assert OrderBook.get_order(amend_result.order_book, "order_1").quantity
             |> Decimal.equal?(Decimal.new("2"))
    end

    test "returns error for non-existent order" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

      assert {:error, _} =
               OrderManager.amend_order(
                 "nonexistent",
                 [price: Decimal.new("50000")],
                 book,
                 accounts
               )
    end

    test "returns error for filled order" do
      book = OrderBook.new("BTC/USD")
      accounts = setup_accounts()

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

      {:ok, sell_result} = OrderManager.place_order(sell_order, book, accounts)

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

      {:ok, result} =
        OrderManager.place_order(buy_order, sell_result.order_book, sell_result.accounts)

      assert {:error, _} =
               OrderManager.amend_order(
                 "buy_1",
                 [price: Decimal.new("51000")],
                 result.order_book,
                 result.accounts
               )
    end
  end

  describe "generate_order_id/0" do
    test "generates unique order IDs" do
      id1 = OrderManager.generate_order_id()
      id2 = OrderManager.generate_order_id()

      assert id1 != id2
      assert String.starts_with?(id1, "order_")
      assert String.starts_with?(id2, "order_")
    end
  end
end
