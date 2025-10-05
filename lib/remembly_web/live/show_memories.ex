defmodule RememblyWeb.ShowMemories do
  use RememblyWeb, :live_view

  require Ash.Query

  @impl true
  def render(assigns) do
    ~H"""
    <div class="memories">
      <h1 class="text-2xl mb-4">Memories</h1>
      <div class="flex justify-between mb-8">
        <div>
          <label class="self-end">Search:</label>
          <input
            type="text"
            placeholder="Search..."
            class="input input-bordered input-secondary w-full max-w-xs self-end"
            phx-debounce="500"
            phx-keyup="search_memories"
          />
        </div>

        <div class="flex gap-4">
          <button phx-click="reset_categories" class="btn btn-link btn-accent self-end pb-0 mb-0">
            reset
          </button>
          <form phx-change="filter_by_category self-end">
            <fieldset class="fieldset min-w-48 pb-0">
              <legend class="fieldset-legend">Filter by source</legend>
              <select
                class="select select-secondary"
                phx-change="filter_by_category"
                value={@category_id}
                name="category_id"
              >
                <option disabled selected value={@category_id}>Select a source</option>
                <%= for source <- @sources do %>
                  <option value={source.value}>{source.label}</option>
                <% end %>
              </select>
            </fieldset>
          </form>
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

      <div class="masonry-grid">
        <.async_result :let={memories} assign={@memories}>
          <:loading>Loading memories...</:loading>
          <%= if Enum.empty?(memories) do %>
            <p>No memories found.</p>
          <% else %>
            <%= for memory <- memories do %>
              <div class="masonry-item">
                <div class="card bg-base-100 shadow-sm border border-base-200">
                  <div class="card-body">
                    <div class="flex items-center justify-between">
                      <h2 class="card-title mr-6">{memory.inserted_at}</h2>
                      <span class="badge badge-primary">{memory.category_label}</span>
                    </div>
                    <span class="font-bold">Content:</span>
                    <p class="overflow-y-auto break-words">
                      {memory.content}
                    </p>
                    <%= if is_nil(memory.og_data) == false && is_nil(memory.og_data.image) == false do %>
                      <div
                        class="relative mt-4 h-48 rounded-lg bg-cover bg-center bg-no-repeat"
                        style={"background-image: url('#{memory.og_data.image}')"}
                      >
                        <div class="absolute inset-0 bg-black bg-opacity-40 rounded-lg"></div>
                        <div class="relative z-10 p-4 h-full flex flex-col justify-between">
                          <%= if memory.og_data.title do %>
                            <h3 class="text-white font-bold text-lg overflow-y-auto">
                              {shorten_string(memory.og_data.title, 40)}
                            </h3>
                          <% end %>
                          <div class="mt-auto">
                            <%= if memory.og_data.description do %>
                              <p class="text-white text-sm mb-2 overflow-y-auto">
                                {memory.og_data.description}
                              </p>
                            <% end %>
                            <%= if memory.og_data.site_name do %>
                              <span class="text-white text-xs opacity-80">
                                {memory.og_data.site_name}
                              </span>
                            <% end %>
                          </div>
                        </div>
                      </div>
                    <% end %>
                    <span>Source: {memory.source}</span>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </.async_result>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(sources: [], categories: fetch_categories(), category_id: nil)
     |> assign_async(:memories, fn -> {:ok, %{memories: fetch_memories()}} end)}
  end

  @impl true
  def handle_event("filter_by_category", params, socket) do
    %{"category_id" => category_id} = params

    {:noreply,
     socket
     |> assign(memories: [])
     |> assign_async(:memories, fn -> {:ok, %{memories: fetch_memories_filtered(category_id)}} end)}
  end

  def fetch_memories_filtered(category_id) do
    Remembly.Remember.Memory
    |> Ash.Query.filter(category_id == ^category_id)
    |> Ash.read!(load: [category: :memory_count])
    |> format_memories()
  end

  @impl true
  def handle_event("search_memories", params, socket) do
    %{"value" => search_value} = params

    if search_value == "" do
      memories = fetch_memories()
      {:noreply, assign(socket, memories: Phoenix.LiveView.AsyncResult.ok(memories))}
    else
      memories =
        Remembly.Remember.remember_memory_by_term!(%{term: search_value},
          load: [category: :memory_count]
        )
        |> format_memories()

      {:noreply, assign(socket, memories: Phoenix.LiveView.AsyncResult.ok(memories))}
    end
  end

  @impl true
  def handle_event("reset_categories", _unsigned_params, socket) do
    {:noreply,
     socket
     |> assign(memories: [], category_id: nil)
     |> assign_async(:memories, fn -> {:ok, %{memories: fetch_memories()}} end)}
  end

  defp fetch_memories do
    memories =
      Remembly.Remember.remember_memories!(load: [category: :memory_count])

    format_memories(memories)
  end

  defp format_memories(memories) do
    Enum.map(memories, fn memory ->
      category_label =
        if memory.category do
          shorten_string(memory.category.label, 14)
        else
          "Uncategorized"
        end

      %{
        id: memory.id,
        content: memory.content,
        og_data:
          RememblyWeb.WebUtils.OgTools.get_urls_from_text(memory.content)
          |> RememblyWeb.WebUtils.OgTools.get_og_image_from_url(),
        inserted_at: Timex.format!(memory.inserted_at, "%Y-%m-%d %H:%M", :strftime),
        category_label: category_label,
        source: memory.source
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
      |> Ash.read!(load: :memory_count)
      |> Enum.map(fn category ->
        %{label: "#{category.label} (#{category.memory_count})", value: category.id}
      end)

    categories
  end
end
