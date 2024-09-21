defmodule RememblyWeb.InteractionsController do
  use RememblyWeb, :controller

  def greet(conn, params) do
    signature = conn |> get_req_header("x-signature-ed25519") |> List.first()
    timestamp = conn |> get_req_header("x-signature-timestamp") |> List.first()
    public_key = System.get_env("DISCORD_PUBLIC_KEY")
    body = conn.private[:raw_body]

    {response, result} =
      DiscordSignatureVerifier.valid_request?(
        signature,
        timestamp,
        body,
        public_key
      )

    dbg(body)

    case response do
      :ok ->
        if params["type"] == 1 do
          conn = conn |> put_resp_content_type("application/json") |> put_status(200)
          json(conn, %{type: 1})
        else
          conn = conn |> put_resp_content_type("application/json") |> put_status(400)
          json(conn, %{error: "unknown command"})
        end

      :error ->
        conn = conn |> put_resp_content_type("application/json") |> put_status(401)
        json(conn, "Bad request signature")
    end
  end
end
