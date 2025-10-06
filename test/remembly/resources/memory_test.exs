defmodule Remembly.Resources.MemoryTest do
  use Remembly.DataCase, async: true

  test "remember_message" do
    assert {:ok, _} =
             Remembly.Remember.create_message_memory(%{
               content: "foobar",
               description: "some description",
               source: "discord",
               message_params: %{content: "message content", reference_id: "ref-1234"}
             })
  end

  test "remember website" do
    assert {:ok, memory} =
             Remembly.Remember.create_website_memory(%{
               description: "some description",
               content: "foobar",
               website_params: %{url: "https://example.com"}
             })

    assert memory.website.url == "https://example.com"
  end

  test "remember website with og data" do
    assert {:ok, memory} =
             Remembly.Remember.create_website_memory(
               %{
                 description: "some description",
                 content: "https://youtube.com",
                 website_params: %{url: "https://youtube.com"}
               },
               load: :og_datas
             )

    assert memory.og_datas |> List.first() |> Map.get(:url) == "https://youtube.com"
  end
end
