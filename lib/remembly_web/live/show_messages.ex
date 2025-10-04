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
              <%= if is_nil(message.og_data) == false && is_nil(message.og_data.image) == false do %>
                <div
                  class="relative mt-4 h-48 rounded-lg bg-cover bg-center bg-no-repeat"
                  style={"background-image: url('#{message.og_data.image}')"}
                >
                  <div class="absolute inset-0 bg-black bg-opacity-40 rounded-lg"></div>
                  <div class="relative z-10 p-4 h-full flex flex-col justify-between">
                    <%= if message.og_data.title do %>
                      <h3 class="text-white font-bold text-lg">{message.og_data.title}</h3>
                    <% end %>
                    <div class="mt-auto">
                      <%= if message.og_data.description do %>
                        <p class="text-white text-sm mb-2">{message.og_data.description}</p>
                      <% end %>
                      <%= if message.og_data.site_name do %>
                        <span class="text-white text-xs opacity-80">{message.og_data.site_name}</span>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
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
      Remembly.Remember.Memory
      |> Ash.Query.filter(category_id == ^params["category_id"])
      |> Ash.read!(load: [category: :message_count])
      |> format_messages()

    {:noreply, assign(socket, messages: messages)}
  end

  def handle_event("reset_categories", _unsigned_params, socket) do
    messages = fetch_messages()

    {:noreply, assign(socket, messages: messages, category_id: nil)}
  end

  defp fetch_messages do
    Remembly.Remember.remember_message_memories!(load: [:category])
    |> format_messages()
  end

  defp format_messages(messages) do
    Enum.map(messages, fn message ->
      category_label =
        if message.category do
          shorten_string(message.category.label, 14)
        else
          "uncategorized"
        end

      %{
        id: message.id,
        content: message.content,
        og_data:
          RememblyWeb.WebUtils.OgTools.get_urls_from_text(message.content)
          |> RememblyWeb.WebUtils.OgTools.get_og_image_from_url(),
        inserted_at: Timex.format!(message.inserted_at, "%Y-%m-%d %H:%M", :strftime),
        category_label: category_label
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
