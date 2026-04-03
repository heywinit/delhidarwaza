defmodule DelhiDarwaza.Trade do
  @moduledoc """
  Trade data structures representing executed trades between orders.
  """

  @typedoc """
  Trade struct representing an executed trade.
  """
  @type t :: %__MODULE__{
          id: String.t(),
          buy_order_id: String.t(),
          sell_order_id: String.t(),
          symbol: String.t(),
          price: Decimal.t(),
          quantity: Decimal.t(),
          timestamp: DateTime.t()
        }

  defstruct [
    :id,
    :buy_order_id,
    :sell_order_id,
    :symbol,
    :price,
    :quantity,
    :timestamp
  ]

  @doc """
  Creates a new trade from matching buy and sell orders.

  ## Examples

      iex> trade = DelhiDarwaza.Trade.new("trade_1", "buy_1", "sell_1", "BTC/USD", Decimal.new("50000"), Decimal.new("0.1"))
      iex> trade.id
      "trade_1"
      iex> trade.price
      #Decimal<50000>
  """
  @spec new(String.t(), String.t(), String.t(), String.t(), Decimal.t(), Decimal.t()) :: t()
  def new(id, buy_order_id, sell_order_id, symbol, price, quantity) do
    %__MODULE__{
      id: id,
      buy_order_id: buy_order_id,
      sell_order_id: sell_order_id,
      symbol: symbol,
      price: price,
      quantity: quantity,
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Returns the notional value of the trade (price * quantity).
  """
  @spec notional_value(t()) :: Decimal.t()
  def notional_value(%__MODULE__{price: price, quantity: quantity}) do
    Decimal.mult(price, quantity)
  end
end
