defmodule DelhiDarwaza.Balance do
  @moduledoc """
  Balance data structure representing available and locked funds for a currency.
  """

  @typedoc """
  Balance struct with available and locked amounts.
  """
  @type t :: %__MODULE__{
          available: Decimal.t(),
          locked: Decimal.t()
        }

  defstruct available: Decimal.new("0"), locked: Decimal.new("0")

  @doc """
  Creates a new balance with the given available amount.
  """
  @spec new(Decimal.t()) :: t()
  def new(available \\ Decimal.new("0")) do
    %__MODULE__{available: available}
  end

  @doc """
  Returns the total balance (available + locked).
  """
  @spec total(t()) :: Decimal.t()
  def total(%__MODULE__{available: available, locked: locked}) do
    Decimal.add(available, locked)
  end

  @doc """
  Locks the specified amount, moving it from available to locked.

  Returns `{:ok, new_balance}` if sufficient available funds, or
  `{:error, reason}` otherwise.
  """
  @spec lock(t(), Decimal.t()) :: {:ok, t()} | {:error, String.t()}
  def lock(%__MODULE__{} = balance, amount) do
    if Decimal.gt?(amount, balance.available) do
      {:error, "Insufficient available balance"}
    else
      {:ok,
       %{
         balance
         | available: Decimal.sub(balance.available, amount),
           locked: Decimal.add(balance.locked, amount)
       }}
    end
  end

  @doc """
  Unlocks the specified amount, moving it from locked to available.

  Returns `{:ok, new_balance}` if sufficient locked funds, or
  `{:error, reason}` otherwise.
  """
  @spec unlock(t(), Decimal.t()) :: {:ok, t()} | {:error, String.t()}
  def unlock(%__MODULE__{} = balance, amount) do
    if Decimal.gt?(amount, balance.locked) do
      {:error, "Insufficient locked balance"}
    else
      {:ok,
       %{
         balance
         | available: Decimal.add(balance.available, amount),
           locked: Decimal.sub(balance.locked, amount)
       }}
    end
  end

  @doc """
  Deducts the specified amount from available balance.

  Returns `{:ok, new_balance}` if sufficient available funds, or
  `{:error, reason}` otherwise.
  """
  @spec deduct(t(), Decimal.t()) :: {:ok, t()} | {:error, String.t()}
  def deduct(%__MODULE__{} = balance, amount) do
    if Decimal.gt?(amount, balance.available) do
      {:error, "Insufficient available balance"}
    else
      {:ok, %{balance | available: Decimal.sub(balance.available, amount)}}
    end
  end

  @doc """
  Credits the specified amount to available balance.
  """
  @spec credit(t(), Decimal.t()) :: {:ok, t()}
  def credit(%__MODULE__{} = balance, amount) do
    {:ok, %{balance | available: Decimal.add(balance.available, amount)}}
  end
end
