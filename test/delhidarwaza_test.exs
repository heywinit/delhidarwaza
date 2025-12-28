defmodule DelhiDarwazaTest do
  @moduledoc """
  Tests for the DelhiDarwaza module.
  """

  use ExUnit.Case
  import ExUnit.CaptureLog
  doctest DelhiDarwaza

  describe "main/0" do
    test "logs the startup message" do
      assert capture_log(fn -> DelhiDarwaza.main() end) =~ "Delhi Darwaza we up"
    end
  end
end
