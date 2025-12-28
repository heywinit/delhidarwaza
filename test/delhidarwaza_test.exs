defmodule DelhiDarwazaTest do
  use ExUnit.Case
  doctest DelhiDarwaza

  describe "main/0" do
    test "prints the startup message" do
      assert ExUnit.CaptureIO.capture_io(fn -> DelhiDarwaza.main() end) == "Delhi Darwaza we up\n"
    end
  end
end
