defmodule RememblyWeb.InteractionTypes.Ping do
  @moduledoc """
  Handles ping interactions for the Remembly Discord bot.
  This module processes ping interactions and generates a response to acknowledge the interaction.
  It is designed to work with the Remembly application, which allows users to remember and recall messages.
  The ping interaction is a simple check to ensure that the bot is responsive and functioning
  """
  use RememblyWeb, :controller

  def commands(conn) do
    conn = conn |> put_resp_content_type("application/json") |> put_status(200)
    json(conn, %{type: 1})
  end
end
