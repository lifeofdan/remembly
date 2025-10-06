defmodule RememblyWeb.ShowMemories do
  use RememblyWeb, :live_view
  import RememblyWeb.WebUtils.Tools, only: [shorten_string: 2]

  require Ash.Query

  @impl true
  def render(assigns) do
    ~H"""
    <div class="memories">
      <div class="flex justify-between">
        <h1 class="text-2xl mb-4">Memories</h1>
        <.button class="bg-primary" phx-click={show_modal("create_memory_modal")}>
          <.icon name="hero-plus-solid" class="h-5 w-5" /> Create Memory
        </.button>
      </div>
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

      <.live_component
        module={RememblyWeb.Live.MemoriesCards}
        id="memories_cards"
        memories={@memories}
      />

      <.modal id="create_memory_modal">
        <.form
          for={@modal_form}
          class="space-y-8"
          phx-change="validate_modal"
          phx-submit="submit_modal"
        >
          <.input type="text" field={@modal_form["content"]} label="Content" />
          <.input type="text" field={@modal_form["description"]} label="Description" />
          <.button type="submit" class="btn btn-primary">
            Save
          </.button>
        </.form>
      </.modal>
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

    modal_form = Remembly.Remember.form_to_create_manual_memory() |> to_form()

    {:ok,
     socket
     |> assign(
       form: form,
       modal_form: modal_form,
       sources: [],
       categories: [],
       show_modal: false,
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
  def handle_event("validate_modal", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.modal_form, params)
    {:noreply, socket |> assign(modal_form: form)}
  end

  @impl true
  def handle_event("submit_modal", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.modal_form, params: params) do
      {:ok, _memory} ->
        socket =
          socket
          |> put_flash(:success, "Memory created successfully")
          |> push_navigate(to: ~p"/memories")

        {:noreply, socket}

      {:error, form} ->
        socket =
          socket
          |> put_flash(:error, "Something went wrong")
          |> assign(:form, form)

        {:noreply, socket}
    end
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
end
