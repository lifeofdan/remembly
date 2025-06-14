defmodule RememblyWeb.InteractionsController do
  require Ash.Expr
  require Ash.Query
  use RememblyWeb, :controller

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
        ping(conn)

      2 ->
        application_command(conn, params)

      3 ->
        message_components(conn, params)

      _ ->
        conn = conn |> put_resp_content_type("application/json") |> put_status(400)
        json(conn, %{error: "unknown command"})
    end
  end

  defp ping(conn) do
    conn = conn |> put_resp_content_type("application/json") |> put_status(200)
    json(conn, %{type: 1})
  end

  defp application_command(conn, params) do
    data = params["data"]

    case data["name"] do
      "test" ->
        conn = conn |> put_resp_content_type("application/json") |> put_status(200)
        json(conn, %{type: 4, data: %{content: "hello from the #{data["name"]} command"}})

      "remember" ->
        remember_command(conn, params)

      "recall" ->
        recall_command(conn)

      _ ->
        conn = conn |> put_resp_content_type("application/json") |> put_status(400)
        json(conn, %{error: "unknown command"})
    end
  end

  defp recall_command(conn) do
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
                custom_id: "message_selection"
              }
            ]
          }
        ],
        flags: 64
      }
    })
  end

  defp remember_command(conn, params) do
    conn = conn |> put_resp_content_type("application/json") |> put_status(200)

    messages = params["data"]["resolved"]["messages"]
    [message_id] = Map.keys(messages)
    message = Map.get(messages, message_id)

    message_exists? =
      Remembly.Remember.Message
      |> Ash.Query.filter(reference_id == ^message_id)
      |> Ash.read!()
      # We do this to make the variable more readable
      |> Enum.empty?() == false

    if message_exists? do
      json(conn, %{type: 4, data: %{content: "Message is already saved"}})
    else
      # We optimistically store the message
      Remembly.Remember.message!(%{reference_id: message_id, content: message["content"]})

      categories =
        Remembly.Remember.Category
        |> Ash.Query.for_read(:read)
        |> Ash.read!()

      categories_exist? =
        categories
        |> Enum.empty?() == false

      # There should be a default category, later we will integrate this on a per-user basis
      category_options =
        if categories_exist? do
          categories
          |> Enum.map(fn category ->
            %{label: category.label, value: category.id}
          end)
        else
          Remembly.Remember.category!(%{label: "Default"})

          Remembly.Remember.Category
          |> Ash.Query.for_read(:read)
          |> Ash.read!()
          |> Enum.map(fn category ->
            %{label: category.label, value: category.id}
          end)
        end

      json(conn, %{
        type: 4,
        context: message,
        data: %{
          content:
            "I will remember this so you don't have to! \n Please select a category or create a new one.",
          components: [
            %{
              type: 1,
              flags: 32768,
              placeholder: "Select a category",
              content: "something here!!!",
              components: [
                %{
                  type: 3,
                  options: category_options,
                  custom_id: "category_selection"
                }
              ]
            },
            %{
              type: 1,
              flags: 32768,
              placeholder: "Select another category",
              components: [
                %{
                  type: 2,
                  style: 1,
                  label: "Create new category",
                  custom_id: "create_category"
                },
                %{
                  type: 2,
                  style: 1,
                  label: "Cancel",
                  custom_id: "cancel_remember"
                }
              ]
            }
          ]
        },
        flags: 64
      })
    end
  end

  defp message_components(conn, params) do
    data = params["data"]
    custom_id = data["custom_id"]

    case custom_id do
      "category_selection" ->
        target_message_id = params["message"]["interaction_metadata"]["target_message_id"]
        [category_id] = data["values"]
        [wrapper, _] = params["message"]["components"]
        [category_component] = wrapper["components"]
        options = category_component["options"]

        # This should never be nil because there should always be at least one option
        %{"label" => category_label} =
          options
          |> Enum.find(fn option ->
            option["value"] == category_id
          end)

        message =
          Remembly.Remember.Message
          |> Ash.Query.filter(Ash.Expr.expr(reference_id == ^target_message_id))
          |> Ash.read_one!()

        message
        |> Ash.Changeset.for_update(:update, %{category_id: category_id})
        |> Ash.update!()

        json(conn, %{
          type: 4,
          data: %{content: "Message stored in the #{category_label} category"}
        })

      "message_selection" ->
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
        json(conn, %{error: "unknown custom_id"})
    end
  end
end
