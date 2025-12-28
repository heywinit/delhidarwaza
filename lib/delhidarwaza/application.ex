defmodule DelhiDarwaza.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    DelhiDarwaza.main()
    Supervisor.start_link([], strategy: :one_for_one, name: DelhiDarwaza.Supervisor)
  end
end
