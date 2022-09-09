defmodule Copilot.Factory do
  @moduledoc """
  Includes functions to easily create objects for tests or in development
  """

  use ExMachina.Ecto, repo: Copilot.Repo

  @spec user_factory() :: %Copilot.Accounts.User{}
  def user_factory do
    %Copilot.Accounts.User{
      name: "Ernest Shackleton",
      email: sequence(:email, &"email-#{&1}@example.com"),
      hashed_password: Argon2.hash_pwd_salt("copilot123"),
      confirmed_at: ~N[2022-05-05 09:00:00]
    }
  end
end
