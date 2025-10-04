defmodule RememblyWeb.WebUtils.OgTools do
  def get_urls_from_text(text) when is_nil(text), do: []

  def get_urls_from_text(text) do
    regex =
      ~r/(?i)\b((?:[a-z][\w-]+:(?:\/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))/

    Regex.scan(regex, text)
    |> Enum.map(fn [url | _] -> url end)
  end

  def get_og_image_from_url([]), do: nil

  def get_og_image_from_url([url | _]) do
    case HTTPoison.get(url, [], follow_redirect: true, max_redirect: 10) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        get_og_image_from_html(body)

      _ ->
        nil
    end
  end

  defp get_og_image_from_html(html) when is_nil(html), do: nil

  defp get_og_image_from_html(html) do
    document = Floki.parse_document!(html)
    og_tags = Floki.find(document, "meta[property^='og:']")

    og_data =
      og_tags
      |> Enum.reduce(%{}, fn tag, acc ->
        case Floki.attribute(tag, "property") do
          [property] ->
            content = Floki.attribute(tag, "content") |> List.first()
            Map.put(acc, property, content)

          _ ->
            acc
        end
      end)

    %{
      title: Map.get(og_data, "og:title"),
      description: Map.get(og_data, "og:description"),
      site_name: Map.get(og_data, "og:site_name"),
      image: Map.get(og_data, "og:image")
    }
  end
end
