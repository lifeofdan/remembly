defmodule RememblyWeb.InteractionTypes.ApplicationCommands do
  @moduledoc """
  Handles application commands for the Remembly Discord bot.
  This module processes commands like "test", "remember", and "recall".
  It also handles the interaction with the Discord API, including command registration and response formatting.
  It is designed to work with the Remembly application, which allows users to remember and recall messages.
  The commands are processed based on the data received from Discord, and appropriate responses are
  generated in JSON format.
  """
  require Ash.Expr
  require Ash.Query

  use RememblyWeb, :controller

  def commands(conn, params) do
    dbg("Received application command interaction")
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

  defp remember_command(conn, params) do
    conn = conn |> put_resp_content_type("application/json") |> put_status(200)

    messages = params["data"]["resolved"]["messages"]
    [message_id] = Map.keys(messages)
    message = Map.get(messages, message_id)

    message_exists? =
      Remembly.Remember.Memory
      |> Ash.Query.filter(message.reference_id == ^message_id)
      |> Ash.read!()
      |> Enum.empty?() == false

    if message_exists? do
      json(conn, %{type: 4, data: %{content: "Message is already saved"}})
    else
      # We optimistically store the message
      Remembly.Remember.create_message_memory!(%{
        source: "discord",
        content: message["content"],
        message_params: %{reference_id: message_id, content: message["content"]}
      })

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
          flags: 64,
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
                  custom_id: "category_selection|#{message_id}"
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
end
