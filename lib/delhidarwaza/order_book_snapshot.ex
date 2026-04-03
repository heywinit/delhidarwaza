defmodule DelhiDarwaza.OrderBookSnapshot do
  @moduledoc """
  Point-in-time snapshot of an order book for serialization or transmission.
  """

  alias DelhiDarwaza.OrderBook

  @typedoc """
  Price level in a snapshot (price with total quantity).
  """
  @type level :: %{price: Decimal.t(), quantity: Decimal.t(), order_count: non_neg_integer()}

  @typedoc """
  Order book snapshot.
  """
  @type t :: %__MODULE__{
          symbol: String.t(),
          bids: [level()],
          asks: [level()],
          timestamp: DateTime.t()
        }

  defstruct [:symbol, bids: [], asks: [], timestamp: DateTime.utc_now()]

  @doc """
  Creates a snapshot from an order book.
  """
  @spec from_order_book(OrderBook.t()) :: t()
  def from_order_book(%OrderBook{symbol: symbol, bids: bids, asks: asks}) do
    %__MODULE__{
      symbol: symbol,
      bids: levels_from_side(bids),
      asks: levels_from_side(asks),
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Creates a snapshot with a maximum depth (number of price levels).
  """
  @spec from_order_book(OrderBook.t(), non_neg_integer()) :: t()
  def from_order_book(%OrderBook{} = book, max_depth) do
    book
    |> from_order_book()
    |> Map.put(:bids, Enum.take(book.bids, max_depth) |> levels_from_side())
    |> Map.put(:asks, Enum.take(book.asks, max_depth) |> levels_from_side())
  end

  defp levels_from_side(levels) do
    Enum.map(levels, fn %{price: price, orders: orders} ->
      %{
        price: price,
        quantity:
          Enum.reduce(orders, Decimal.new("0"), fn o, acc ->
            Decimal.sub(o.quantity, o.filled_quantity) |> Decimal.add(acc)
          end),
        order_count: length(orders)
      }
    end)
  end
end
