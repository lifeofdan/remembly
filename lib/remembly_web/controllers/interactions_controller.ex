defmodule RememblyWeb.InteractionsController do
  require Ash.Query
  use RememblyWeb, :controller

  def index(conn, params) do
    signature = conn |> get_req_header("x-signature-ed25519") |> List.first()
    timestamp = conn |> get_req_header("x-signature-timestamp") |> List.first()
    public_key = System.get_env("DISCORD_PUBLIC_KEY")
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
    data = params["data"]

    case params["type"] do
      1 ->
        conn = conn |> put_resp_content_type("application/json") |> put_status(200)
        json(conn, %{type: 1})

      2 ->
        case data["name"] do
          "test" ->
            conn = conn |> put_resp_content_type("application/json") |> put_status(200)
            json(conn, %{type: 4, data: %{content: "hello from the #{data["name"]} command"}})

          "remember" ->
            messages = params["data"]["resolved"]["messages"]
            [message_id] = Map.keys(messages)
            message = Map.get(messages, message_id)

            Remembly.Remember.message!(%{content: message["content"]})

            conn = conn |> put_resp_content_type("application/json") |> put_status(200)

            json(conn, %{
              type: 4,
              data: %{content: "I will remember this so you don't have to!", flags: 64}
            })

          "recall" ->
            messages =
              Remembly.Remember.Message
              |> Ash.Query.for_read(:read)
              |> Ash.read!()
              |> Ash.load!(:short_content)

            options =
              Enum.map(messages, fn message ->
                %{label: message.short_content, value: message.id}
              end)

            json(conn, %{
              type: 4,
              data: %{
                content: "Saved messages",
                components: [
                  %{
                    type: 1,
                    placeholder: "foo",
                    components: [
                      %{
                        type: 3,
                        options: options,
                        custom_id: "foo"
                      }
                    ]
                  }
                ],
                flags: 64
              }
            })

          _ ->
            conn = conn |> put_resp_content_type("application/json") |> put_status(400)
            json(conn, %{error: "unknown command"})
        end

      3 ->
        [message_id] = data["values"]

        message =
          Remembly.Remember.Message
          |> Ash.Query.filter(id == ^message_id)
          |> Ash.read_first!()

        json(conn, %{
          type: 7,
          data: %{
            content: message.content,
            components: [],
            flags: 64
          }
        })

      _ ->
        conn = conn |> put_resp_content_type("application/json") |> put_status(400)
        json(conn, %{error: "unknown command"})
    end
  end
end
