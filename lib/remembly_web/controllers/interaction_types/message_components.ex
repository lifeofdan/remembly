defmodule RememblyWeb.InteractionTypes.MessageComponents do
  @moduledoc """
  Handles message component interactions for the Remembly Discord bot.
  This module processes interactions with message components, such as buttons and select menus,
  and generates appropriate responses based on the interaction type.
  """
  require Ash.Expr
  require Ash.Query

  use RememblyWeb, :controller

  @base_url "https://discord.com/api/v10"

  def commands(conn, params) do
    data = params["data"]
    custom_id = data["custom_id"]

    cond do
      String.contains?(custom_id, "category_selection") ->
        dbg("selecting category")
        target_message_id = params["message"]["interaction_metadata"]["target_message_id"]
        [category_id] = data["values"]
        [wrapper, _] = params["message"]["components"]
        [category_component] = wrapper["components"]
        options = category_component["options"]

        target_message_id =
          if is_nil(target_message_id) do
            [_, tail] = String.split(custom_id, "|")
            tail
          else
            target_message_id
          end

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

        app_id = Application.get_env(:remembly, :application_id)
        token = params["token"]
        m_id = params["message"]["id"]

        Task.async(fn ->
          HTTPoison.delete("#{@base_url}/webhooks/#{app_id}/#{token}/messages/#{m_id}")
        end)

        json(conn, %{
          type: 4,
          data: %{flags: 64, content: "Message stored in the #{category_label} category"}
        })

      String.contains?(custom_id, "create_category") ->
        json(conn, %{
          type: 9,
          data: %{
            custom_id: "create_category_form",
            title: "Create Category",
            components: [
              %{
                type: 1,
                components: [
                  %{
                    type: 4,
                    custom_id: "category_name",
                    label: "Category Name",
                    style: 1,
                    min_length: 1,
                    max_length: 100,
                    placeholder: "Give your category a name",
                    required: true
                  }
                ]
              }
            ]
          }
        })

      String.contains?(custom_id, "message_selection") ->
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

      true ->
        conn = conn |> put_resp_content_type("application/json") |> put_status(400)
        json(conn, %{error: "unknown custom_id"})
    end
  end
end
