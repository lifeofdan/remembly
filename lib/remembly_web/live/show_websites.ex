defmodule RememblyWeb.ShowWebsites do
  use RememblyWeb, :live_view

  require Ash.Query

  @impl true
  def render(assigns) do
    ~H"""
    <div class="messages">
      <div class="flex justify-between mb-8">
        <h1 class="text-2xl mb-4">Websites</h1>

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
        <%= for website <- @websites do %>
          <div class="card bg-base-100 w-96 shadow-sm border border-base-200">
            <div class="card-body">
              <div class="flex items-center justify-between">
                <h2 class="card-title mr-6">{website.inserted_at}</h2>
                <span class="badge badge-primary">
                  <!-- put category label -->
                </span>
              </div>
              <p>
                {website.url}
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
     assign(socket, websites: fetch_websites(), categories: fetch_categories(), category_id: nil)}
  end

  @impl true
  def handle_event("filter_by_category", params, socket) do
    websites =
      Remembly.Remember.Website
      |> Ash.Query.for_read(:read)
      |> Ash.Query.filter(category_id == ^params["category_id"])
      |> Ash.read!()
      |> Ash.load!(category: [:website_count])

    {:noreply, assign(socket, websites: websites)}
  end

  def handle_event("reset_categories", _unsigned_params, socket) do
    websites = fetch_websites()

    {:noreply, assign(socket, websites: websites, category_id: nil)}
  end

  defp fetch_websites do
    Remembly.Remember.Website
    |> Ash.Query.for_read(:read)
    |> Ash.read!()
    |> Ash.load!(category: [:website_count])
  end

  defp fetch_categories do
    categories =
      Remembly.Remember.Category
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Ash.load!(:website_count)
      |> Enum.map(fn category ->
        %{label: "#{category.label} (#{category.website_count})", value: category.id}
      end)

    categories
  end
end
