defmodule RememblyWeb.ShowMessages do
  use RememblyWeb, :live_view

  require Ash.Query

  @impl true
  def render(assigns) do
    ~H"""
    <div class="messages">
      <div class="flex justify-between mb-8">
        <h1 class="text-2xl mb-4">Messages</h1>

        <div class="flex gap-4">
          <button phx-click="reset_categories" class="btn btn-link btn-accent self-end pb-0 mb-0">
            reset
          </button>
          <form phx-change="filter_by_category self-end">
            <fieldset class="fieldset min-w-48 pb-0">
              <legend class="fieldset-legend">Filter by category</legend>
              <select
                class="select select-secondary"
                phx-change="filter_by_category"
                value={@category_id}
                name="category_id"
              >
                <option disabled selected value={@category_id}>Select a category</option>
                <%= for category <- @categories do %>
                  <option value={category.value}>{category.label}</option>
                <% end %>
              </select>
            </fieldset>
          </form>
        </div>
      </div>
      <div class="flex flex-wrap gap-4">
        <%= for message <- @messages do %>
          <div class="card bg-base-100 w-96 shadow-sm border border-base-200">
            <div class="card-body">
              <div class="flex items-center justify-between">
                <h2 class="card-title mr-6">{message.inserted_at}</h2>
                <span class="badge badge-primary">{message.category_label}</span>
              </div>
              <p>
                {message.content}
              </p>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, messages: fetch_messages(), categories: fetch_categories(), category_id: nil)}
  end

  @impl true
  def handle_event("filter_by_category", params, socket) do
    messages =
      Remembly.Remember.Message
      |> Ash.Query.for_read(:read)
      |> Ash.Query.filter(category_id == ^params["category_id"])
      |> Ash.read!()
      |> Ash.load!(category: [:message_count])
      |> format_messages()

    {:noreply, assign(socket, messages: messages)}
  end

  def handle_event("reset_categories", _unsigned_params, socket) do
    messages = fetch_messages()

    {:noreply, assign(socket, messages: messages, category_id: nil)}
  end

  defp fetch_messages do
    messages =
      Remembly.Remember.Message
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Ash.load!(category: [:message_count])

    format_messages(messages)
  end

  defp format_messages(messages) do
    Enum.map(messages, fn message ->
      %{
        id: message.id,
        content: message.content,
        inserted_at: Timex.format!(message.inserted_at, "%Y-%m-%d %H:%M", :strftime),
        category_label:
          "#{shorten_string(message.category.label, 14)} (#{message.category.message_count})",
        message_count: message.category.message_count
      }
    end)
  end

  defp shorten_string(string, max_length) do
    short = String.slice(string, 0..max_length)

    if String.length(short) >= 14 do
      short <> "..."
    else
      short
    end
  end

  defp fetch_categories do
    categories =
      Remembly.Remember.Category
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Ash.load!(:message_count)
      |> Enum.map(fn category ->
        %{label: "#{category.label} (#{category.message_count})", value: category.id}
      end)

    categories
  end
end
