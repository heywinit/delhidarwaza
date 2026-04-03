defmodule DelhiDarwaza.Account do
  @moduledoc """
  Account data structure managing user balances across multiple currencies.
  """

  alias DelhiDarwaza.Balance

  @typedoc """
  Account struct with a map of currency symbol to Balance.
  """
  @type t :: %__MODULE__{
          user_id: String.t(),
          balances: %{String.t() => Balance.t()}
        }

  defstruct [:user_id, balances: %{}]

  @doc """
  Creates a new account for the given user.
  """
  @spec new(String.t()) :: t()
  def new(user_id) do
    %__MODULE__{user_id: user_id}
  end

  @doc """
  Gets the balance for a specific currency.

  Returns a zero balance if the currency is not found.
  """
  @spec get_balance(t(), String.t()) :: Balance.t()
  def get_balance(%__MODULE__{} = account, currency) do
    Map.get(account.balances, currency, Balance.new())
  end

  @doc """
  Deposits funds into the available balance for a currency.
  """
  @spec deposit(t(), String.t(), Decimal.t()) :: t()
  def deposit(%__MODULE__{} = account, currency, amount) do
    current = get_balance(account, currency)

    {:ok, new_balance} = Balance.credit(current, amount)

    %{account | balances: Map.put(account.balances, currency, new_balance)}
  end

  @doc """
  Locks funds for a currency (e.g., when placing an order).

  Returns `{:ok, new_account}` or `{:error, reason}`.
  """
  @spec lock_funds(t(), String.t(), Decimal.t()) :: {:ok, t()} | {:error, String.t()}
  def lock_funds(%__MODULE__{} = account, currency, amount) do
    current = get_balance(account, currency)

    case Balance.lock(current, amount) do
      {:ok, new_balance} ->
        {:ok, %{account | balances: Map.put(account.balances, currency, new_balance)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Unlocks funds for a currency (e.g., when cancelling an order).

  Returns `{:ok, new_account}` or `{:error, reason}`.
  """
  @spec unlock_funds(t(), String.t(), Decimal.t()) :: {:ok, t()} | {:error, String.t()}
  def unlock_funds(%__MODULE__{} = account, currency, amount) do
    current = get_balance(account, currency)

    case Balance.unlock(current, amount) do
      {:ok, new_balance} ->
        {:ok, %{account | balances: Map.put(account.balances, currency, new_balance)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Deducts funds from available balance (e.g., when a buy order fills).

  Returns `{:ok, new_account}` or `{:error, reason}`.
  """
  @spec deduct_funds(t(), String.t(), Decimal.t()) :: {:ok, t()} | {:error, String.t()}
  def deduct_funds(%__MODULE__{} = account, currency, amount) do
    current = get_balance(account, currency)

    case Balance.deduct(current, amount) do
      {:ok, new_balance} ->
        {:ok, %{account | balances: Map.put(account.balances, currency, new_balance)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Credits funds to available balance (e.g., when a sell order fills).
  """
  @spec credit_funds(t(), String.t(), Decimal.t()) :: t()
  def credit_funds(%__MODULE__{} = account, currency, amount) do
    current = get_balance(account, currency)
    {:ok, new_balance} = Balance.credit(current, amount)
    %{account | balances: Map.put(account.balances, currency, new_balance)}
  end

  @doc """
  Returns all non-zero balances.
  """
  @spec portfolio(t()) :: %{String.t() => Balance.t()}
  def portfolio(%__MODULE__{balances: balances}) do
    balances
    |> Enum.filter(fn {_, balance} ->
      not Decimal.equal?(Balance.total(balance), Decimal.new("0"))
    end)
    |> Map.new()
  end
end
