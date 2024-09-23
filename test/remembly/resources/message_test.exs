defmodule Remembly.Resources.MessageTest do
  use Remembly.DataCase, async: true

  test "remember message" do
    assert {:ok, _} =
             Remembly.Remember.message(%{content: "foobar"})
  end
end
