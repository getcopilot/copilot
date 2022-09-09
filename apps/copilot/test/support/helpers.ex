defmodule Copilot.TestHelpers do
  @moduledoc false

  @spec extract_user_token((String.t() -> %Swoosh.Email{})) :: binary
  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
