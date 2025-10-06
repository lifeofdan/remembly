defmodule Remembly.Remember.Memory.Actions.FetchOgData do
  def process(_changeset, record, _context) do
    urls =
      record.content
      |> RememblyWeb.WebUtils.OgTools.get_urls_from_text()

    og_data =
      urls
      |> RememblyWeb.WebUtils.OgTools.get_og_data_from_url()

    if not is_nil(og_data) and Enum.any?(urls) do
      Remembly.Remember.create_og_data!(%{
        memory_id: record.id,
        url: urls |> List.first(),
        title: Map.get(og_data, :title),
        description: Map.get(og_data, :description),
        site_name: Map.get(og_data, :site_name),
        image: Map.get(og_data, :image)
      })
    end

    {:ok, record}
  end
end
