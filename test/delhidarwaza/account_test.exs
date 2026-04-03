defmodule DelhiDarwaza.AccountTest do
  use ExUnit.Case, async: true

  alias DelhiDarwaza.Account

  describe "new/1" do
    test "creates an empty account" do
      account = Account.new("user_1")

      assert account.user_id == "user_1"
      assert account.balances == %{}
    end
  end

  describe "get_balance/2" do
    test "returns zero balance for unknown currency" do
      account = Account.new("user_1")
      balance = Account.get_balance(account, "USD")

      assert Decimal.equal?(balance.available, Decimal.new("0"))
    end
  end

  describe "deposit/3" do
    test "adds funds to available balance" do
      account = Account.new("user_1")

      account = Account.deposit(account, "USD", Decimal.new("1000"))

      balance = Account.get_balance(account, "USD")
      assert Decimal.equal?(balance.available, Decimal.new("1000"))
    end
  end

  describe "lock_funds/3" do
    test "moves funds from available to locked" do
      account =
        Account.new("user_1")
        |> Account.deposit("USD", Decimal.new("1000"))

      {:ok, account} = Account.lock_funds(account, "USD", Decimal.new("300"))

      balance = Account.get_balance(account, "USD")
      assert Decimal.equal?(balance.available, Decimal.new("700"))
      assert Decimal.equal?(balance.locked, Decimal.new("300"))
    end

    test "returns error when insufficient funds" do
      account =
        Account.new("user_1")
        |> Account.deposit("USD", Decimal.new("100"))

      assert {:error, _} = Account.lock_funds(account, "USD", Decimal.new("200"))
    end
  end

  describe "unlock_funds/3" do
    test "moves funds from locked to available" do
      account =
        Account.new("user_1")
        |> Account.deposit("USD", Decimal.new("1000"))

      {:ok, account} = Account.lock_funds(account, "USD", Decimal.new("300"))
      {:ok, account} = Account.unlock_funds(account, "USD", Decimal.new("200"))

      balance = Account.get_balance(account, "USD")
      assert Decimal.equal?(balance.available, Decimal.new("900"))
      assert Decimal.equal?(balance.locked, Decimal.new("100"))
    end

    test "returns error when insufficient locked funds" do
      account =
        Account.new("user_1")
        |> Account.deposit("USD", Decimal.new("1000"))

      {:ok, account} = Account.lock_funds(account, "USD", Decimal.new("100"))
      assert {:error, _} = Account.unlock_funds(account, "USD", Decimal.new("200"))
    end
  end

  describe "deduct_funds/3" do
    test "reduces available balance" do
      account =
        Account.new("user_1")
        |> Account.deposit("USD", Decimal.new("1000"))

      {:ok, account} = Account.deduct_funds(account, "USD", Decimal.new("300"))

      balance = Account.get_balance(account, "USD")
      assert Decimal.equal?(balance.available, Decimal.new("700"))
    end

    test "returns error when insufficient funds" do
      account =
        Account.new("user_1")
        |> Account.deposit("USD", Decimal.new("100"))

      assert {:error, _} = Account.deduct_funds(account, "USD", Decimal.new("200"))
    end
  end

  describe "credit_funds/3" do
    test "increases available balance" do
      account =
        Account.new("user_1")
        |> Account.deposit("USD", Decimal.new("1000"))

      account = Account.credit_funds(account, "USD", Decimal.new("500"))

      balance = Account.get_balance(account, "USD")
      assert Decimal.equal?(balance.available, Decimal.new("1500"))
    end
  end

  describe "portfolio/1" do
    test "returns only non-zero balances" do
      account =
        Account.new("user_1")
        |> Account.deposit("USD", Decimal.new("1000"))
        |> Account.deposit("BTC", Decimal.new("0.5"))

      portfolio = Account.portfolio(account)

      assert Map.has_key?(portfolio, "USD")
      assert Map.has_key?(portfolio, "BTC")
    end
  end
end
