defmodule RememblyWeb.ShowMemories do
  use RememblyWeb, :live_view

  require Ash.Query

  @impl true
  def render(assigns) do
    ~H"""
    <div class="memories">
      <h1 class="text-2xl mb-4">Memories</h1>
      <div class="flex mb-8">
        <.form for={@form} phx-change="filter" phx-debounce="300" class="flex justify-end gap-4">
          <fieldset class="fieldset min-w-48 pb-0">
            <legend class="fieldset-legend">Search</legend>
            <.input type="text" placeholder="Search..." field={@form["search_value"]} />
          </fieldset>
          <fieldset class="fieldset min-w-48 pb-0">
            <legend class="fieldset-legend">Filter by source</legend>
            <.input
              type="select"
              class="select select-secondary"
              field={@form["source_value"]}
              name="source_value"
              options={@sources}
            />
          </fieldset>
          <fieldset class="fieldset min-w-48 pb-0">
            <legend class="fieldset-legend">Filter by category</legend>
            <.input
              type="select"
              class="select select-secondary"
              field={@form["category_id"]}
              name="category_id"
              options={@categories}
            />
          </fieldset>
        </.form>
        <button phx-click="reset_filter" class="btn btn-link btn-accent self-end pb-0 mb-0">
          reset
        </button>
      </div>

      <div class="masonry-grid">
        <.async_result :let={memories} assign={@memories}>
          <:loading>Loading memories...</:loading>
          <%= if Enum.empty?(memories) do %>
            <p>No memories found.</p>
          <% else %>
            <%= for memory <- memories do %>
              <div class="masonry-item">
                <div class="card text-neutral-content shadow-sm border border-primary">
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
                            <h3 class="text-white font-bold text-lg">
                              {shorten_string(memory.og_data.title, 40)}
                            </h3>
                          <% end %>
                          <div class="mt-auto">
                            <%= if memory.og_data.description do %>
                              <p class="text-white text-sm mb-2 overflow-hidden">
                                {shorten_string(memory.og_data.description, 60)}
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
                    <div class="flex flex-col mt-2">
                      <div>
                        <span class="px-2 py-1 bg-neutral rounded rounded-lg">
                          {memory.source}
                        </span>
                      </div>
                    </div>
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
    form =
      to_form(%{
        "search_value" => "",
        "category_id" => "",
        "source_value" => ""
      })

    {:ok,
     socket
     |> assign(
       form: form,
       sources: [],
       categories: [],
       memories: Phoenix.LiveView.AsyncResult.loading(),
       categories: []
     )
     |> start_async(:get_memories, fn -> fetch_memories() end)}
  end

  @impl true
  def handle_async(:get_memories, {:ok, fetched_memories}, socket) do
    %{memories: memories} = socket.assigns

    sources = get_sources(fetched_memories)
    categories = get_categories()

    {:noreply,
     socket
     |> assign(
       memories: Phoenix.LiveView.AsyncResult.ok(memories, fetched_memories),
       sources: sources,
       categories: categories
     )}
  end

  @impl true
  def handle_event("filter", params, socket) do
    memories = fetch_filtered_memories(params)

    {:noreply,
     socket
     |> assign_async(:memories, fn ->
       {:ok, %{memories: memories}}
     end)}
  end

  @impl true
  def handle_event("reset_filter", _unsigned_params, socket) do
    {:noreply, push_navigate(socket, to: "/memories")}
  end

  defp fetch_memories do
    memories =
      Remembly.Remember.remember_memories!(load: [:og_datas, category: :memory_count])

    format_memories(memories)
  end

  defp fetch_filtered_memories(params) do
    term = Map.get(params, "search_value", "")
    category_id = Map.get(params, "category_id", nil)
    source_value = Map.get(params, "source_value", nil)

    query =
      Remembly.Remember.Memory
      |> Ash.Query.for_read(:remember_memories, %{term: term})
      |> Ash.Query.load([:og_datas, category: :memory_count])

    query =
      if source_value != "" do
        Ash.Query.filter(query, source == ^source_value)
      else
        query
      end

    query =
      if category_id != "" do
        Ash.Query.filter(query, category_id == ^category_id)
      else
        query
      end

    memories = Ash.read!(query)

    format_memories(memories)
  end

  defp get_sources(memories) do
    sources = [{"All", ""}]

    memories =
      memories
      |> Enum.map(& &1.source)
      |> Enum.uniq()
      |> Enum.map(fn source -> {String.capitalize(source), source} end)

    sources ++ memories
  end

  defp get_categories do
    default =
      [{"All", ""}]

    categories =
      Remembly.Remember.Category
      |> Ash.Query.for_read(:read)
      |> Ash.read!(load: :memory_count)
      |> Enum.map(fn category ->
        {"#{category.label} (#{category.memory_count})", category.id}
      end)

    default ++ categories
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
        og_data: memory.og_datas |> List.first(),
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
end
