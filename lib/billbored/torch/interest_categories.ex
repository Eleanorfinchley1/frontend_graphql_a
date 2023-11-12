defmodule BillBored.Torch.InterestCategories do
  import Ecto.Query, warn: false

  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  alias BillBored.InterestCategory

  @pagination [page_size: 15]
  @pagination_distance 5

  def paginate(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "name")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <- Filtrex.parse_params(filter_config(:interest_categories), params["interest_category"] || %{}) do
      %Scrivener.Page{} = page =
        InterestCategory
        |> Filtrex.query(filter)
        |> order_by(^sort(params))
        |> paginate(Repo, params, @pagination)

      {:ok,
        %{
          interest_categories: page.entries,
          page_number: page.page_number,
          page_size: page.page_size,
          total_pages: page.total_pages,
          total_entries: page.total_entries,
          distance: @pagination_distance,
          sort_field: sort_field,
          sort_direction: sort_direction
        }
      }
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  def get(id) do
    Repo.get!(InterestCategory, id) |> Repo.preload(:interests)
  end

  def delete(%InterestCategory{id: id} = interest_category) do
    Repo.transaction(fn ->
      from(i in "interest_categories_interests", where: i.interest_category_id == ^id) |> Repo.delete_all()
      Repo.delete(interest_category)
    end)
  end

  defp filter_config(:interest_categories) do
    defconfig do
      number(:id)
      text(:name)
    end
  end
end
