defmodule DelhiDarwaza.Ticker do
  @moduledoc """
  Market ticker providing 24-hour statistics for a trading symbol.
  """

  @typedoc """
  Ticker struct with 24h market statistics.
  """
  @type t :: %__MODULE__{
          symbol: String.t(),
          last_price: Decimal.t() | nil,
          volume_24h: Decimal.t(),
          high_24h: Decimal.t() | nil,
          low_24h: Decimal.t() | nil,
          open_price: Decimal.t() | nil,
          price_change: Decimal.t() | nil,
          price_change_percent: Decimal.t() | nil,
          timestamp: DateTime.t()
        }

  defstruct [
    :symbol,
    :last_price,
    :volume_24h,
    :high_24h,
    :low_24h,
    :open_price,
    :price_change,
    :price_change_percent,
    timestamp: DateTime.utc_now()
  ]

  @doc """
  Creates a new empty ticker for the given symbol.
  """
  @spec new(String.t()) :: t()
  def new(symbol) do
    %__MODULE__{
      symbol: symbol,
      volume_24h: Decimal.new("0")
    }
  end

  @doc """
  Updates the ticker with a new trade.
  """
  @spec update_with_trade(t(), Decimal.t(), Decimal.t()) :: t()
  def update_with_trade(%__MODULE__{} = ticker, price, quantity) do
    now = DateTime.utc_now()

    high =
      if is_nil(ticker.high_24h) or Decimal.gt?(price, ticker.high_24h) do
        price
      else
        ticker.high_24h
      end

    low =
      if is_nil(ticker.low_24h) or Decimal.lt?(price, ticker.low_24h) do
        price
      else
        ticker.low_24h
      end

    volume = Decimal.add(ticker.volume_24h, quantity)

    price_change =
      if ticker.open_price, do: Decimal.sub(price, ticker.open_price), else: nil

    price_change_percent =
      if price_change && ticker.open_price &&
           not Decimal.equal?(ticker.open_price, Decimal.new("0")) do
        Decimal.mult(Decimal.div(price_change, ticker.open_price), Decimal.new("100"))
      else
        nil
      end

    %{
      ticker
      | last_price: price,
        volume_24h: volume,
        high_24h: high,
        low_24h: low,
        price_change: price_change,
        price_change_percent: price_change_percent,
        timestamp: now
    }
  end
end
