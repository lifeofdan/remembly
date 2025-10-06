defmodule RememblyWeb.Live.MemoriesCards do
  use Phoenix.LiveComponent
  import RememblyWeb.WebUtils.Tools, only: [shorten_string: 2]

  def render(assigns) do
    ~H"""
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
    """
  end
end
