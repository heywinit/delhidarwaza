defmodule DelhiDarwaza.OrderManager do
  @moduledoc """
  Order lifecycle management: placement, cancellation, and modification.

  Orchestrates order validation, balance locking/unlocking, and order book operations.
  """

  require Logger

  alias DelhiDarwaza.Account
  alias DelhiDarwaza.MatchingEngine
  alias DelhiDarwaza.Order
  alias DelhiDarwaza.OrderBook

  @typedoc """
  Result of placing an order.
  """
  @type place_result ::
          {:ok, place_success()}
          | {:error, place_error()}

  @type place_success :: %{
          order: Order.t(),
          trades: [DelhiDarwaza.Trade.t()],
          order_book: OrderBook.t(),
          accounts: %{String.t() => Account.t()}
        }

  @type place_error :: String.t()

  @typedoc """
  Result of cancelling an order.
  """
  @type cancel_result ::
          {:ok, cancel_success()}
          | {:error, cancel_error()}

  @type cancel_success :: %{
          order: Order.t(),
          order_book: OrderBook.t(),
          accounts: %{String.t() => Account.t()}
        }

  @type cancel_error :: String.t()

  @typedoc """
  Result of amending an order.
  """
  @type amend_result ::
          {:ok, amend_success()}
          | {:error, amend_error()}

  @type amend_success :: %{
          order: Order.t(),
          trades: [DelhiDarwaza.Trade.t()],
          order_book: OrderBook.t(),
          accounts: %{String.t() => Account.t()}
        }

  @type amend_error :: String.t()

  @doc """
  Places a new order.

  Validates the order, locks required balances, inserts into the order book,
  and attempts to match.
  """
  @spec place_order(Order.t(), OrderBook.t(), %{String.t() => Account.t()}) :: place_result()
  def place_order(%Order{} = order, %OrderBook{} = book, %{} = accounts) do
    with :ok <- Order.validate(order),
         :ok <- validate_cancellable_status(order),
         {:ok, accounts} <- lock_funds(order, accounts),
         {:ok, book} <- add_to_book(order, book) do
      order = Order.update_status(order, :active)
      result = MatchingEngine.match_order(order, book, accounts)

      {final_order, final_book} =
        if result.remaining_order do
          {result.remaining_order, result.order_book}
        else
          order = Order.update_status(order, :filled)
          {:ok, book} = OrderBook.remove_order(result.order_book, order.id)
          {order, book}
        end

      Logger.info("Order placed",
        component: :order,
        event: :placed,
        order_id: final_order.id,
        user_id: final_order.user_id,
        symbol: final_order.symbol
      )

      {:ok,
       %{
         order: final_order,
         trades: result.trades,
         order_book: final_book,
         accounts: result.accounts
       }}
    else
      {:error, reason} ->
        Logger.warning("Order placement failed",
          component: :order,
          event: :placement_failed,
          order_id: order.id,
          reason: reason
        )

        {:error, reason}
    end
  end

  @doc """
  Cancels an open order.

  Removes from the order book, unlocks any remaining locked funds,
  and updates status.
  """
  @spec cancel_order(String.t(), OrderBook.t(), %{String.t() => Account.t()}) :: cancel_result()
  def cancel_order(order_id, %OrderBook{} = book, %{} = accounts) do
    case OrderBook.get_order(book, order_id) do
      nil ->
        {:error, "Order not found: #{order_id}"}

      order ->
        if not Order.cancellable?(order) do
          {:error, "Order cannot be cancelled: #{order.status}"}
        else
          with {:ok, book} <- OrderBook.remove_order(book, order_id),
               {:ok, accounts} <- unlock_funds(order, book, accounts) do
            order = Order.update_status(order, :cancelled)

            Logger.info("Order cancelled",
              component: :order,
              event: :cancelled,
              order_id: order_id,
              user_id: order.user_id
            )

            {:ok,
             %{
               order: order,
               order_book: book,
               accounts: accounts
             }}
          else
            {:error, reason} ->
              {:error, reason}
          end
        end
    end
  end

  @doc """
  Amends an existing order's price and/or quantity.

  Cancels the old order (unlocking funds), creates a new order with
  updated parameters, and attempts to match.
  """
  @spec amend_order(String.t(), Keyword.t(), OrderBook.t(), %{String.t() => Account.t()}) ::
          amend_result()
  def amend_order(order_id, amendments, %OrderBook{} = book, %{} = accounts) do
    case OrderBook.get_order(book, order_id) do
      nil ->
        {:error, "Order not found: #{order_id}"}

      order ->
        if not Order.cancellable?(order) do
          {:error, "Order cannot be amended: #{order.status}"}
        else
          amended_order = apply_amendments(order, amendments)

          with :ok <- Order.validate(amended_order),
               {:ok, cancel_result} <- cancel_order(order_id, book, accounts) do
            place_order(
              %{amended_order | id: order_id},
              cancel_result.order_book,
              cancel_result.accounts
            )
          else
            {:error, reason} ->
              {:error, reason}
          end
        end
    end
  end

  @doc """
  Generates a unique order ID.
  """
  @spec generate_order_id() :: String.t()
  def generate_order_id() do
    n = System.unique_integer([:positive, :monotonic])
    "order_#{n}"
  end

  # Private helpers

  defp validate_cancellable_status(%Order{status: status}) do
    if Order.cancellable?(%Order{status: status}) do
      :ok
    else
      {:error, "Order cannot be placed: #{status}"}
    end
  end

  defp lock_funds(%Order{side: :buy, type: :limit, price: price} = order, accounts) do
    quote_currency = get_quote_currency(order.symbol)
    required = Decimal.mult(price, order.quantity)

    case Map.fetch(accounts, order.user_id) do
      {:ok, account} ->
        case Account.lock_funds(account, quote_currency, required) do
          {:ok, account} ->
            {:ok, Map.put(accounts, order.user_id, account)}

          {:error, reason} ->
            {:error, reason}
        end

      :error ->
        {:error, "Account not found for user: #{order.user_id}"}
    end
  end

  defp lock_funds(%Order{side: :buy, type: :market} = order, accounts) do
    quote_currency = get_quote_currency(order.symbol)

    case Map.fetch(accounts, order.user_id) do
      {:ok, account} ->
        balance = Account.get_balance(account, quote_currency)

        if Decimal.gt?(balance.available, Decimal.new("0")) do
          {:ok, accounts}
        else
          {:error, "Insufficient balance for market buy"}
        end

      :error ->
        {:error, "Account not found for user: #{order.user_id}"}
    end
  end

  defp lock_funds(%Order{side: :sell} = order, accounts) do
    base_currency = get_base_currency(order.symbol)

    case Map.fetch(accounts, order.user_id) do
      {:ok, account} ->
        case Account.lock_funds(account, base_currency, order.quantity) do
          {:ok, account} ->
            {:ok, Map.put(accounts, order.user_id, account)}

          {:error, reason} ->
            {:error, reason}
        end

      :error ->
        {:error, "Account not found for user: #{order.user_id}"}
    end
  end

  defp unlock_funds(order, _book, accounts) do
    remaining_qty = Decimal.sub(order.quantity, order.filled_quantity)

    if Decimal.equal?(remaining_qty, Decimal.new("0")) do
      {:ok, accounts}
    else
      case Map.fetch(accounts, order.user_id) do
        {:ok, account} ->
          account =
            case order.side do
              :buy ->
                quote_currency = get_quote_currency(order.symbol)

                if order.type == :limit do
                  amount = Decimal.mult(order.price, remaining_qty)
                  {:ok, account} = Account.unlock_funds(account, quote_currency, amount)
                  account
                else
                  account
                end

              :sell ->
                base_currency = get_base_currency(order.symbol)
                {:ok, account} = Account.unlock_funds(account, base_currency, remaining_qty)
                account
            end

          {:ok, Map.put(accounts, order.user_id, account)}

        :error ->
          {:ok, accounts}
      end
    end
  end

  defp add_to_book(%Order{} = order, %OrderBook{} = book) do
    {:ok, OrderBook.add_order(book, order)}
  end

  defp apply_amendments(order, amendments) do
    Enum.reduce(amendments, order, fn
      {:price, price}, acc -> %{acc | price: price}
      {:quantity, quantity}, acc -> %{acc | quantity: quantity}
      _, acc -> acc
    end)
  end

  defp get_base_currency(symbol) do
    symbol |> String.split("/") |> hd()
  end

  defp get_quote_currency(symbol) do
    symbol |> String.split("/") |> List.last()
  end
end
