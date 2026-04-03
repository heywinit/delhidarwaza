defmodule DelhiDarwaza.BalanceTest do
  use ExUnit.Case, async: true

  alias DelhiDarwaza.Balance

  describe "new/1" do
    test "creates a zero balance by default" do
      balance = Balance.new()

      assert Decimal.equal?(balance.available, Decimal.new("0"))
      assert Decimal.equal?(balance.locked, Decimal.new("0"))
    end

    test "creates a balance with the given available amount" do
      balance = Balance.new(Decimal.new("1000"))

      assert Decimal.equal?(balance.available, Decimal.new("1000"))
      assert Decimal.equal?(balance.locked, Decimal.new("0"))
    end
  end

  describe "total/1" do
    test "returns available + locked" do
      balance = %Balance{available: Decimal.new("500"), locked: Decimal.new("200")}

      assert Decimal.equal?(Balance.total(balance), Decimal.new("700"))
    end
  end

  describe "lock/2" do
    test "moves amount from available to locked" do
      balance = Balance.new(Decimal.new("1000"))

      {:ok, new_balance} = Balance.lock(balance, Decimal.new("300"))

      assert Decimal.equal?(new_balance.available, Decimal.new("700"))
      assert Decimal.equal?(new_balance.locked, Decimal.new("300"))
    end

    test "returns error when insufficient available balance" do
      balance = Balance.new(Decimal.new("100"))

      assert {:error, _} = Balance.lock(balance, Decimal.new("200"))
    end
  end

  describe "unlock/2" do
    test "moves amount from locked to available" do
      balance = %Balance{available: Decimal.new("700"), locked: Decimal.new("300")}

      {:ok, new_balance} = Balance.unlock(balance, Decimal.new("200"))

      assert Decimal.equal?(new_balance.available, Decimal.new("900"))
      assert Decimal.equal?(new_balance.locked, Decimal.new("100"))
    end

    test "returns error when insufficient locked balance" do
      balance = %Balance{available: Decimal.new("700"), locked: Decimal.new("100")}

      assert {:error, _} = Balance.unlock(balance, Decimal.new("200"))
    end
  end

  describe "deduct/2" do
    test "reduces available balance" do
      balance = Balance.new(Decimal.new("1000"))

      {:ok, new_balance} = Balance.deduct(balance, Decimal.new("300"))

      assert Decimal.equal?(new_balance.available, Decimal.new("700"))
      assert Decimal.equal?(new_balance.locked, Decimal.new("0"))
    end

    test "returns error when insufficient available balance" do
      balance = Balance.new(Decimal.new("100"))

      assert {:error, _} = Balance.deduct(balance, Decimal.new("200"))
    end
  end

  describe "credit/2" do
    test "increases available balance" do
      balance = Balance.new(Decimal.new("1000"))

      {:ok, new_balance} = Balance.credit(balance, Decimal.new("500"))

      assert Decimal.equal?(new_balance.available, Decimal.new("1500"))
    end
  end
end
