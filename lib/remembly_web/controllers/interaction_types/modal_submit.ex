defmodule RememblyWeb.InteractionTypes.ModalSubmit do
  @moduledoc """
  Handles modal submit interactions for the Remembly Discord bot.
  This module processes interactions when a user submits a modal form, such as creating a new category.
  It generates appropriate responses based on the submitted data and interacts with the Remembly application
  to perform actions like creating a new category in the database.
  """
  require Ash.Expr
  require Ash.Query
  use RememblyWeb, :controller

  @base_url "https://discord.com/api/v10"

  def commands(conn, params) do
    message_components = params["message"]["components"]
    [%{"components" => [%{"value" => label}]}] = params["data"]["components"]

    category_exits? =
      Remembly.Remember.Category
      |> Ash.Query.filter(label == ^label)
      |> Ash.read!()
      |> Enum.empty?() ==
        false

    case category_exits? do
      true ->
        app_id = Application.get_env(:remembly, :application_id)
        token = params["token"]
        m_id = params["message"]["id"]

        Task.async(fn ->
          HTTPoison.delete("#{@base_url}/webhooks/#{app_id}/#{token}/messages/#{m_id}")
        end)

        response = %{
          type: 4,
          data: %{
            content:
              "I will remember this so you don't have to! \n Please select a category or create a new one.",
            components: message_components
          }
        }

        json(conn, response)

      false ->
        Remembly.Remember.category!(%{label: label})

        category_options =
          Remembly.Remember.Category
          |> Ash.Query.for_read(:read)
          |> Ash.read!()
          |> Enum.map(fn category ->
            %{label: category.label, value: category.id}
          end)

        [%{"components" => [%{"custom_id" => category_selection_id}]}, _] = message_components

        app_id = Application.get_env(:remembly, :application_id)
        token = params["token"]
        m_id = params["message"]["id"]

        Task.async(fn ->
          HTTPoison.delete("#{@base_url}/webhooks/#{app_id}/#{token}/messages/#{m_id}")
        end)

        response = %{
          type: 4,
          data: %{
            content:
              "I will remember this so you don't have to! \n Please select a category or create a new one.",
            components: [
              %{
                "components" => [
                  %{
                    "custom_id" => category_selection_id,
                    "id" => 2,
                    "max_values" => 1,
                    "min_values" => 1,
                    "options" => category_options,
                    "type" => 3
                  }
                ],
                "id" => 1,
                "type" => 1
              },
              %{
                "components" => [
                  %{
                    "custom_id" => "create_category",
                    "id" => 4,
                    "label" => "Create new category",
                    "style" => 1,
                    "type" => 2
                  },
                  %{
                    "custom_id" => "cancel_remember",
                    "id" => 5,
                    "label" => "Cancel",
                    "style" => 1,
                    "type" => 2
                  }
                ],
                "id" => 3,
                "type" => 1
              }
            ]
          }
        }

        json(conn, response)
    end
  end
end
