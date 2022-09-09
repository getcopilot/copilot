defmodule Copilot.Mailer do
  @moduledoc """
  Base module for emails
  """

  use Swoosh.Mailer, otp_app: :copilot
end
