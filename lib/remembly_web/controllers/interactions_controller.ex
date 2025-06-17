defmodule RememblyWeb.InteractionsController do
  require Ash.Expr
  require Ash.Query
  use RememblyWeb, :controller

  alias RememblyWeb.InteractionTypes.ApplicationCommands
  alias RememblyWeb.InteractionTypes.MessageComponents
  alias RememblyWeb.InteractionTypes.Ping
  alias RememblyWeb.InteractionTypes.ModalSubmit

  def index(conn, params) do
    signature = conn |> get_req_header("x-signature-ed25519") |> List.first()
    timestamp = conn |> get_req_header("x-signature-timestamp") |> List.first()
    public_key = Application.get_env(:remembly, :discord_public_key)
    body = params |> Jason.encode!()

    {response, _} =
      DiscordSignatureVerifier.valid_request?(
        signature,
        timestamp,
        body,
        public_key
      )

    case response do
      :ok ->
        do_command(conn, params)

      :error ->
        conn = conn |> put_resp_content_type("application/json") |> put_status(401)
        json(conn, "Bad request signature")
    end
  end

  defp do_command(conn, params) do
    case params["type"] do
      1 ->
        Ping.commands(conn)

      2 ->
        ApplicationCommands.commands(conn, params)

      3 ->
        MessageComponents.commands(conn, params)

      5 ->
        ModalSubmit.commands(conn, params)

      _ ->
        conn = conn |> put_resp_content_type("application/json") |> put_status(400)
        json(conn, %{error: "unknown command"})
    end
  end
end
