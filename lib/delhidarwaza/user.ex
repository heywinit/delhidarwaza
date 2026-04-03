defmodule DelhiDarwaza.User do
  @moduledoc """
  User data structure for the trading exchange.
  """

  @typedoc """
  User struct.
  """
  @type t :: %__MODULE__{
          id: String.t(),
          username: String.t(),
          email: String.t(),
          created_at: DateTime.t()
        }

  defstruct [:id, :username, :email, created_at: DateTime.utc_now()]

  @doc """
  Creates a new user.

  ## Examples

      iex> user = DelhiDarwaza.User.new("user_1", "trader", "trader@example.com")
      iex> user.username
      "trader"
  """
  @spec new(String.t(), String.t(), String.t()) :: t()
  def new(id, username, email) do
    %__MODULE__{
      id: id,
      username: username,
      email: email
    }
  end
end
