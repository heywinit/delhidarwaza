defmodule DelhiDarwaza.MatchingEngine do
  @moduledoc """
  Order matching engine implementing price-time priority matching.

  Supports market, limit, stop, and stop-limit orders with partial and full fill handling.
  """

  alias DelhiDarwaza.Account
  alias DelhiDarwaza.Order
  alias DelhiDarwaza.OrderBook
  alias DelhiDarwaza.Trade

  @typedoc """
  Result of matching an order.
  """
  @type match_result :: %{
          trades: [Trade.t()],
          remaining_order: Order.t() | nil,
          order_book: OrderBook.t(),
          accounts: %{String.t() => Account.t()}
        }

  @doc """
  Matches an incoming order against the order book.

  Returns the trades created, any remaining order, the updated order book,
  and updated accounts.
  """
  @spec match_order(Order.t(), OrderBook.t(), %{String.t() => Account.t()}) :: match_result()
  def match_order(%Order{type: :stop} = order, book, accounts) do
    %{
      trades: [],
      remaining_order: order,
      order_book: book,
      accounts: accounts
    }
  end

  def match_order(%Order{type: :stop_limit} = order, book, accounts) do
    %{
      trades: [],
      remaining_order: order,
      order_book: book,
      accounts: accounts
    }
  end

  def match_order(%Order{} = order, book, accounts) do
    available_qty = Decimal.sub(order.quantity, order.filled_quantity)

    if Decimal.equal?(available_qty, Decimal.new("0")) do
      %{trades: [], remaining_order: nil, order_book: book, accounts: accounts}
    else
      order = %{order | quantity: available_qty, filled_quantity: Decimal.new("0")}
      {trades, remaining, book} = do_match(order, book, [])
      remaining_order = build_remaining_order(remaining)
      accounts = Enum.reduce(trades, accounts, &update_accounts(&2, &1))

      %{
        trades: trades,
        remaining_order: remaining_order,
        order_book: book,
        accounts: accounts
      }
    end
  end

  defp build_remaining_order(nil), do: nil

  defp build_remaining_order(rem_order) do
    if Decimal.equal?(rem_order.filled_quantity, rem_order.quantity) do
      nil
    else
      %{rem_order | status: :active}
    end
  end

  defp do_match(%Order{type: :market, side: :buy} = order, book, trades) do
    match_market_buy(order, book, trades)
  end

  defp do_match(%Order{type: :market, side: :sell} = order, book, trades) do
    match_market_sell(order, book, trades)
  end

  defp do_match(%Order{type: :limit, side: :buy} = order, book, trades) do
    match_limit_buy(order, book, trades)
  end

  defp do_match(%Order{type: :limit, side: :sell} = order, book, trades) do
    match_limit_sell(order, book, trades)
  end

  defp match_market_buy(order, book, trades) do
    match_against_asks(order, book, trades, fn _order, _ask -> true end)
  end

  defp match_market_sell(order, book, trades) do
    match_against_bids(order, book, trades, fn _order, _bid -> true end)
  end

  defp match_limit_buy(order, book, trades) do
    match_against_asks(order, book, trades, fn order, ask ->
      Decimal.gte?(order.price, ask.price)
    end)
  end

  defp match_limit_sell(order, book, trades) do
    match_against_bids(order, book, trades, fn order, bid ->
      Decimal.lte?(order.price, bid.price)
    end)
  end

  defp match_against_asks(order, book, trades, price_check?) do
    case OrderBook.best_ask(book) do
      nil ->
        {Enum.reverse(trades), order, book}

      ask ->
        remaining_qty = Decimal.sub(order.quantity, order.filled_quantity)

        can_match? =
          price_check?.(order, ask) and not Decimal.equal?(remaining_qty, Decimal.new("0"))

        if can_match? do
          execute_ask_match(order, ask, book, trades, price_check?)
        else
          {Enum.reverse(trades), order, book}
        end
    end
  end

  defp match_against_bids(order, book, trades, price_check?) do
    case OrderBook.best_bid(book) do
      nil ->
        {Enum.reverse(trades), order, book}

      bid ->
        remaining_qty = Decimal.sub(order.quantity, order.filled_quantity)

        can_match? =
          price_check?.(order, bid) and not Decimal.equal?(remaining_qty, Decimal.new("0"))

        if can_match? do
          execute_bid_match(order, bid, book, trades, price_check?)
        else
          {Enum.reverse(trades), order, book}
        end
    end
  end

  defp execute_ask_match(order, ask, book, trades, price_check?) do
    ask_remaining = Decimal.sub(ask.quantity, ask.filled_quantity)
    trade_qty = decimal_min(Decimal.sub(order.quantity, order.filled_quantity), ask_remaining)

    trade = Trade.new(generate_trade_id(), order.id, ask.id, order.symbol, ask.price, trade_qty)
    new_order = %{order | filled_quantity: Decimal.add(order.filled_quantity, trade_qty)}
    updated_ask = %{ask | filled_quantity: Decimal.add(ask.filled_quantity, trade_qty)}

    book = update_book_after_match(book, updated_ask)
    match_against_asks(new_order, book, [trade | trades], price_check?)
  end

  defp execute_bid_match(order, bid, book, trades, price_check?) do
    bid_remaining = Decimal.sub(bid.quantity, bid.filled_quantity)
    trade_qty = decimal_min(Decimal.sub(order.quantity, order.filled_quantity), bid_remaining)

    trade = Trade.new(generate_trade_id(), bid.id, order.id, order.symbol, bid.price, trade_qty)
    new_order = %{order | filled_quantity: Decimal.add(order.filled_quantity, trade_qty)}
    updated_bid = %{bid | filled_quantity: Decimal.add(bid.filled_quantity, trade_qty)}

    book = update_book_after_match(book, updated_bid)
    match_against_bids(new_order, book, [trade | trades], price_check?)
  end

  defp update_book_after_match(book, matched_order) do
    if Decimal.equal?(matched_order.filled_quantity, matched_order.quantity) do
      {:ok, book} = OrderBook.remove_order(book, matched_order.id)
      book
    else
      {:ok, book} = OrderBook.update_order(book, matched_order)
      book
    end
  end

  defp decimal_min(a, b) do
    if Decimal.lte?(a, b), do: a, else: b
  end

  defp update_accounts(accounts, %Trade{
         buy_order_id: buy_id,
         sell_order_id: sell_id,
         price: price,
         quantity: qty,
         symbol: symbol
       }) do
    notional = Decimal.mult(price, qty)

    accounts
    |> update_buyer_account(buy_id, symbol, qty, notional)
    |> update_seller_account(sell_id, symbol, qty, notional)
  end

  defp update_buyer_account(accounts, buy_order_id, symbol, qty, _notional) do
    case find_account_for_order(accounts, buy_order_id) do
      {user_id, account} ->
        base_currency = get_base_currency(symbol)
        account = Account.credit_funds(account, base_currency, qty)
        Map.put(accounts, user_id, account)

      nil ->
        accounts
    end
  end

  defp update_seller_account(accounts, sell_order_id, symbol, _qty, notional) do
    case find_account_for_order(accounts, sell_order_id) do
      {user_id, account} ->
        quote_currency = get_quote_currency(symbol)
        account = Account.credit_funds(account, quote_currency, notional)
        Map.put(accounts, user_id, account)

      nil ->
        accounts
    end
  end

  defp find_account_for_order(accounts, order_id) do
    Enum.find_value(accounts, fn {user_id, account} ->
      if Map.has_key?(account.balances, order_id) do
        {user_id, account}
      else
        nil
      end
    end)
  end

  defp get_base_currency(symbol) do
    symbol |> String.split("/") |> hd()
  end

  defp get_quote_currency(symbol) do
    symbol |> String.split("/") |> List.last()
  end

  defp generate_trade_id() do
    n = System.unique_integer([:positive, :monotonic])
    "trade_#{n}"
  end
end
