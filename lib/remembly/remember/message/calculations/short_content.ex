defmodule Remembly.Remember.Message.Calculations.ShortContent do
  use Ash.Resource.Calculation

  def calculate(records, _opts, _context) do
    Enum.map(records, fn record ->
      String.slice(record.content, 0..96) <> "..."
    end)
  end
end
