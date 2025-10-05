defmodule Remembly.Remember.Memory.Preparations.Find do
  use Ash.Resource.Preparation
  require Ash.Query

  def prepare(query, _opts, _context) do
    term = Ash.Query.get_argument(query, :term)
    maybe_find(query, term)
  end

  def maybe_find(query, term) when is_nil(term) do
    query
  end

  def maybe_find(query, term) do
    query
    |> Ash.Query.filter(
      expr(
        ilike(content, "%" <> ^term <> "%") ||
          ilike(description, "%" <> ^term <> "%") ||
          ilike(category.label, "%" <> ^term <> "%")
      )
    )
  end
end
