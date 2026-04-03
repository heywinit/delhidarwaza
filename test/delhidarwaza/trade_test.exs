defmodule DelhiDarwaza.TradeTest do
  use ExUnit.Case, async: true

  alias DelhiDarwaza.Trade

  describe "new/6" do
    test "creates a trade with the given parameters" do
      trade =
        Trade.new(
          "trade_1",
          "buy_1",
          "sell_1",
          "BTC/USD",
          Decimal.new("50000"),
          Decimal.new("0.5")
        )

      assert trade.id == "trade_1"
      assert trade.buy_order_id == "buy_1"
      assert trade.sell_order_id == "sell_1"
      assert trade.symbol == "BTC/USD"
      assert Decimal.equal?(trade.price, Decimal.new("50000"))
      assert Decimal.equal?(trade.quantity, Decimal.new("0.5"))
      refute is_nil(trade.timestamp)
    end
  end

  describe "notional_value/1" do
    test "returns price * quantity" do
      trade =
        Trade.new(
          "trade_1",
          "buy_1",
          "sell_1",
          "BTC/USD",
          Decimal.new("50000"),
          Decimal.new("0.5")
        )

      assert Decimal.equal?(Trade.notional_value(trade), Decimal.new("25000"))
    end
  end
end
