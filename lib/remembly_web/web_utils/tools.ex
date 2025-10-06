defmodule RememblyWeb.WebUtils.Tools do
  def shorten_string(string, max_length) do
    short = String.slice(string, 0..max_length)

    if String.length(short) >= 14 do
      short <> "..."
    else
      short
    end
  end
end
