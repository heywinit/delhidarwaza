defmodule DelhiDarwaza.TickerTest do
  use ExUnit.Case, async: true

  alias DelhiDarwaza.Ticker

  describe "new/1" do
    test "creates an empty ticker for the symbol" do
      ticker = Ticker.new("BTC/USD")

      assert ticker.symbol == "BTC/USD"
      assert is_nil(ticker.last_price)
      assert Decimal.equal?(ticker.volume_24h, Decimal.new("0"))
      assert is_nil(ticker.high_24h)
      assert is_nil(ticker.low_24h)
    end
  end

  describe "update_with_trade/3" do
    test "updates last price and volume" do
      ticker = Ticker.new("BTC/USD")

      ticker = Ticker.update_with_trade(ticker, Decimal.new("50000"), Decimal.new("1"))

      assert Decimal.equal?(ticker.last_price, Decimal.new("50000"))
      assert Decimal.equal?(ticker.volume_24h, Decimal.new("1"))
    end

    test "tracks high and low" do
      ticker = Ticker.new("BTC/USD")

      ticker = Ticker.update_with_trade(ticker, Decimal.new("50000"), Decimal.new("1"))
      ticker = Ticker.update_with_trade(ticker, Decimal.new("51000"), Decimal.new("1"))
      ticker = Ticker.update_with_trade(ticker, Decimal.new("49000"), Decimal.new("1"))

      assert Decimal.equal?(ticker.high_24h, Decimal.new("51000"))
      assert Decimal.equal?(ticker.low_24h, Decimal.new("49000"))
    end

    test "calculates price change and percent" do
      ticker = Ticker.new("BTC/USD")
      ticker = %{ticker | open_price: Decimal.new("50000")}

      ticker = Ticker.update_with_trade(ticker, Decimal.new("52000"), Decimal.new("1"))

      assert Decimal.equal?(ticker.price_change, Decimal.new("2000"))
      assert Decimal.equal?(ticker.price_change_percent, Decimal.new("4"))
    end

    test "accumulates volume" do
      ticker = Ticker.new("BTC/USD")

      ticker = Ticker.update_with_trade(ticker, Decimal.new("50000"), Decimal.new("1"))
      ticker = Ticker.update_with_trade(ticker, Decimal.new("50000"), Decimal.new("2"))

      assert Decimal.equal?(ticker.volume_24h, Decimal.new("3"))
    end
  end
end
