defmodule DelhiDarwaza.Order do
  @moduledoc """
  Order data structures and enums for the trading exchange.

  Defines the Order struct and related enums for order side, type, and status.
  """

  @typedoc """
  Order side: Buy or Sell
  """
  @type side :: :buy | :sell

  @typedoc """
  Order type: Market, Limit, Stop, or Stop-Limit
  """
  @type order_type :: :market | :limit | :stop | :stop_limit

  @typedoc """
  Order status: Pending, Active, Filled, PartiallyFilled, Cancelled, or Rejected
  """
  @type status :: :pending | :active | :filled | :partially_filled | :cancelled | :rejected

  @typedoc """
  Order struct representing a trading order.
  """
  @type t :: %__MODULE__{
          id: String.t(),
          user_id: String.t(),
          symbol: String.t(),
          side: side(),
          type: order_type(),
          price: Decimal.t() | nil,
          quantity: Decimal.t(),
          filled_quantity: Decimal.t(),
          status: status(),
          timestamp: DateTime.t(),
          created_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  defstruct [
    :id,
    :user_id,
    :symbol,
    :side,
    :type,
    :price,
    :quantity,
    :filled_quantity,
    :status,
    :timestamp,
    :created_at,
    :updated_at
  ]

  @doc """
  Validates if a value is a valid order side.
  """
  @spec valid_side?(atom()) :: boolean()
  def valid_side?(:buy), do: true
  def valid_side?(:sell), do: true
  def valid_side?(_), do: false

  @doc """
  Validates if a value is a valid order type.
  """
  @spec valid_type?(atom()) :: boolean()
  def valid_type?(:market), do: true
  def valid_type?(:limit), do: true
  def valid_type?(:stop), do: true
  def valid_type?(:stop_limit), do: true
  def valid_type?(_), do: false

  @doc """
  Validates if a value is a valid order status.
  """
  @spec valid_status?(atom()) :: boolean()
  def valid_status?(:pending), do: true
  def valid_status?(:active), do: true
  def valid_status?(:filled), do: true
  def valid_status?(:partially_filled), do: true
  def valid_status?(:cancelled), do: true
  def valid_status?(:rejected), do: true
  def valid_status?(_), do: false

  @doc """
  Creates a new order with the given parameters.

  ## Examples

      iex> order = DelhiDarwaza.Order.new("order_1", "user_1", "BTC/USD", :buy, :limit, Decimal.new("50000"), Decimal.new("0.5"))
      iex> order.id
      "order_1"
      iex> order.status
      :pending
  """
  @spec new(
          String.t(),
          String.t(),
          String.t(),
          side(),
          order_type(),
          Decimal.t() | nil,
          Decimal.t()
        ) ::
          t()
  def new(id, user_id, symbol, side, type, price, quantity) do
    now = DateTime.utc_now()

    %__MODULE__{
      id: id,
      user_id: user_id,
      symbol: symbol,
      side: side,
      type: type,
      price: price,
      quantity: quantity,
      filled_quantity: Decimal.new("0"),
      status: :pending,
      timestamp: now,
      created_at: now,
      updated_at: now
    }
  end

  @doc """
  Validates an order struct.

  Returns `:ok` if valid, or `{:error, reason}` if invalid.
  """
  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = order) do
    cond do
      not valid_side?(order.side) ->
        {:error, "Invalid order side: #{inspect(order.side)}"}

      not valid_type?(order.type) ->
        {:error, "Invalid order type: #{inspect(order.type)}"}

      not valid_status?(order.status) ->
        {:error, "Invalid order status: #{inspect(order.status)}"}

      order.type == :limit and is_nil(order.price) ->
        {:error, "Limit orders must have a price"}

      order.type == :stop_limit and is_nil(order.price) ->
        {:error, "Stop-limit orders must have a price"}

      Decimal.negative?(order.quantity) or Decimal.equal?(order.quantity, Decimal.new("0")) ->
        {:error, "Quantity must be positive"}

      Decimal.negative?(order.filled_quantity) ->
        {:error, "Filled quantity cannot be negative"}

      Decimal.gt?(order.filled_quantity, order.quantity) ->
        {:error, "Filled quantity cannot exceed order quantity"}

      true ->
        :ok
    end
  end

  @doc """
  Checks if an order is a buy order.
  """
  @spec buy?(t()) :: boolean()
  def buy?(%__MODULE__{side: :buy}), do: true
  def buy?(_), do: false

  @doc """
  Checks if an order is a sell order.
  """
  @spec sell?(t()) :: boolean()
  def sell?(%__MODULE__{side: :sell}), do: true
  def sell?(_), do: false

  @doc """
  Checks if an order is fully filled.
  """
  @spec filled?(t()) :: boolean()
  def filled?(%__MODULE__{status: :filled}), do: true

  def filled?(%__MODULE__{quantity: qty, filled_quantity: filled}) do
    Decimal.equal?(qty, filled)
  end

  @doc """
  Checks if an order is active (can be matched).
  """
  @spec active?(t()) :: boolean()
  def active?(%__MODULE__{status: status}) do
    status in [:pending, :active, :partially_filled]
  end

  @doc """
  Checks if an order can be cancelled.
  """
  @spec cancellable?(t()) :: boolean()
  def cancellable?(%__MODULE__{status: status}) do
    status in [:pending, :active, :partially_filled]
  end

  @doc """
  Updates the order status.
  """
  @spec update_status(t(), status()) :: t()
  def update_status(%__MODULE__{} = order, status) when is_atom(status) do
    %{order | status: status, updated_at: DateTime.utc_now()}
  end

  @doc """
  Updates the filled quantity of an order.
  """
  @spec update_filled_quantity(t(), Decimal.t()) :: t()
  def update_filled_quantity(%__MODULE__{} = order, filled_qty) do
    new_status =
      cond do
        Decimal.equal?(filled_qty, order.quantity) -> :filled
        Decimal.gt?(filled_qty, Decimal.new(0)) -> :partially_filled
        true -> order.status
      end

    %{
      order
      | filled_quantity: filled_qty,
        status: new_status,
        updated_at: DateTime.utc_now()
    }
  end
end
