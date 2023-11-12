defmodule Web.ViewHelpers do
  import Phoenix.Controller, only: [current_url: 1, current_path: 1, current_path: 2]

  @moduledoc """
  Helpers for pagination.
  """
  defp url(conn, page) do
    path = String.length(current_path(conn))
    base = String.slice(current_url(conn), 0..(-path - 1))

    base <> current_path(conn, page: page)
  end

  @doc """
  Returns indexed representation.
  """
  def index(conn, data, module, template \\ "show.json") do
    page = conn.params["page"]
    page = (page && String.to_integer(page)) || 1

    %{
      page_number: data.page_number,
      page_size: data.page_size,
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      prev: if(page > 1, do: url(conn, page - 1)),
      next: if(page < data.total_pages, do: url(conn, page + 1)),
      entries: Phoenix.View.render_many(data.entries, module, template, conn.assigns)
    }
  end

  def put_assoc(map, key, assoc, view_module, view_name, opts \\ []) do
    if Ecto.assoc_loaded?(assoc) do
      Map.put(map, key, Phoenix.View.render_one(assoc, view_module, view_name, Keyword.take(opts, [:as])))
    else
      if opts[:required] do
        raise "Missing required assoc #{inspect(key)}"
      else
        map
      end
    end
  end
end
