defmodule RememblyWeb.InteractionsController do
  use RememblyWeb, :controller

  def greet(conn, params) do
    signature = conn |> get_req_header("x-signature-ed25519") |> List.first()
    timestamp = conn |> get_req_header("x-signature-timestamp") |> List.first()
    public_key = System.get_env("DISCORD_PUBLIC_KEY")
    {_, raw_body} = get_raw_body(conn)

    {response, _} =
      DiscordSignatureVerifier.valid_request?(
        signature,
        timestamp,
        raw_body,
        public_key
      )

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

  defp get_raw_body(conn) do
    case conn.private[:raw_body] do
      nil -> {:error, "No raw body present"}
      raw_body -> {:ok, raw_body}
    end
  end
end
