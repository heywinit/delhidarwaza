defmodule DelhiDarwaza.OrderBook do
  @moduledoc """
  Order book for a trading symbol with price-time priority matching.

  Maintains separate bid (buy) and ask (sell) sides with orders sorted
  by price then time. Provides O(1) order lookup by ID.
  """

  alias DelhiDarwaza.Order

  @typedoc """
  Price level in the order book.
  """
  @type price_level :: %{price: Decimal.t(), orders: [Order.t()]}

  @typedoc """
  Order book struct.
  """
  @type t :: %__MODULE__{
          symbol: String.t(),
          bids: [price_level()],
          asks: [price_level()],
          orders: %{String.t() => Order.t()}
        }

  defstruct [:symbol, bids: [], asks: [], orders: %{}]

  @doc """
  Creates a new order book for the given symbol.
  """
  @spec new(String.t()) :: t()
  def new(symbol) do
    %__MODULE__{symbol: symbol}
  end

  @doc """
  Adds an order to the order book.

  Buy orders go to bids (sorted descending by price), sell orders to asks
  (sorted ascending by price). Orders at the same price are time-prioritized.
  """
  @spec add_order(t(), Order.t()) :: t()
  def add_order(%__MODULE__{} = book, %Order{} = order) do
    book = update_in(book.orders, &Map.put(&1, order.id, order))

    case order.side do
      :buy -> put_bid(book, order)
      :sell -> put_ask(book, order)
    end
  end

  @doc """
  Removes an order from the order book by ID.
  """
  @spec remove_order(t(), String.t()) :: {:ok, t()} | {:error, String.t()}
  def remove_order(%__MODULE__{} = book, order_id) do
    case Map.pop(book.orders, order_id) do
      {nil, _} ->
        {:error, "Order not found: #{order_id}"}

      {order, orders} ->
        book = %{book | orders: orders}

        book =
          case order.side do
            :buy -> remove_from_side(book, :bids, order_id)
            :sell -> remove_from_side(book, :asks, order_id)
          end

        {:ok, book}
    end
  end

  @doc """
  Updates an order in the book.
  """
  @spec update_order(t(), Order.t()) :: {:ok, t()} | {:error, String.t()}
  def update_order(%__MODULE__{} = book, %Order{} = order) do
    if Map.has_key?(book.orders, order.id) do
      with {:ok, book} <- remove_order(book, order.id) do
        {:ok, add_order(book, order)}
      end
    else
      {:error, "Order not found: #{order.id}"}
    end
  end

  @doc """
  Gets an order by ID.
  """
  @spec get_order(t(), String.t()) :: Order.t() | nil
  def get_order(%__MODULE__{} = book, order_id) do
    Map.get(book.orders, order_id)
  end

  @doc """
  Returns the best bid (highest price).
  """
  @spec best_bid(t()) :: Order.t() | nil
  def best_bid(%__MODULE__{bids: []}), do: nil

  def best_bid(%__MODULE__{bids: [%{orders: [order | _]} | _]}), do: order

  @doc """
  Returns the best ask (lowest price).
  """
  @spec best_ask(t()) :: Order.t() | nil
  def best_ask(%__MODULE__{asks: []}), do: nil

  def best_ask(%__MODULE__{asks: [%{orders: [order | _]} | _]}), do: order

  @doc """
  Returns the bid-ask spread, or nil if either side is empty.
  """
  @spec spread(t()) :: Decimal.t() | nil
  def spread(%__MODULE__{} = book) do
    case {best_bid(book), best_ask(book)} do
      {bid, ask} when not is_nil(bid) and not is_nil(ask) ->
        Decimal.sub(ask.price, bid.price)

      _ ->
        nil
    end
  end

  @doc """
  Returns the number of orders on each side.
  """
  @spec depth(t()) :: %{bid_count: non_neg_integer(), ask_count: non_neg_integer()}
  def depth(%__MODULE__{bids: bids, asks: asks}) do
    %{
      bid_count: Enum.reduce(bids, 0, fn level, acc -> acc + length(level.orders) end),
      ask_count: Enum.reduce(asks, 0, fn level, acc -> acc + length(level.orders) end)
    }
  end

  @doc """
  Returns all price levels for the given side.
  """
  @spec price_levels(t(), :bid | :ask) :: [price_level()]
  def price_levels(%__MODULE__{bids: bids}, :bid), do: bids
  def price_levels(%__MODULE__{asks: asks}, :ask), do: asks

  @doc """
  Checks if the order book is empty.
  """
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{bids: [], asks: []}), do: true
  def empty?(_), do: false

  # Private helpers

  defp put_bid(%__MODULE__{} = book, %Order{} = order) do
    put_side(book, :bids, order, :desc)
  end

  defp put_ask(%__MODULE__{} = book, %Order{} = order) do
    put_side(book, :asks, order, :asc)
  end

  defp put_side(%__MODULE__{} = book, side_key, %Order{} = order, sort_dir) do
    levels = Map.get(book, side_key)
    {new_levels, found} = insert_at_price(levels, order)

    if found do
      Map.put(book, side_key, new_levels)
    else
      new_level = %{price: order.price, orders: [order]}
      Map.put(book, side_key, sort_levels([new_level | new_levels], sort_dir))
    end
  end

  defp insert_at_price(levels, order) do
    Enum.map_reduce(levels, false, fn
      %{price: price, orders: orders} = level, false when price == order.price ->
        {%{level | orders: orders ++ [order]}, true}

      level, found ->
        {level, found}
    end)
  end

  defp sort_levels(levels, :asc),
    do: Enum.sort(levels, fn a, b -> Decimal.lte?(a.price, b.price) end)

  defp sort_levels(levels, :desc),
    do: Enum.sort(levels, fn a, b -> Decimal.gte?(a.price, b.price) end)

  defp remove_from_side(%__MODULE__{} = book, side_key, order_id) do
    new_levels =
      book
      |> Map.get(side_key)
      |> Enum.map(fn %{price: price, orders: orders} ->
        %{price: price, orders: Enum.reject(orders, &(&1.id == order_id))}
      end)
      |> Enum.reject(fn %{orders: orders} -> orders == [] end)

    Map.put(book, side_key, new_levels)
  end
end
