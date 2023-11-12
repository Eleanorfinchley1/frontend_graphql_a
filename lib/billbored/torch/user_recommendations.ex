defmodule BillBored.Torch.UserRecommendations do
  @moduledoc false

  import Ecto.Query
  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  alias BillBored.User.Recommendation

  @pagination [page_size: 15]
  @pagination_distance 5

  def get!(id) do
    Repo.get!(Recommendation, id)
  end

  def create(attrs) do
    Repo.insert(Recommendation.changeset(%Recommendation{}, attrs))
  end

  def delete(%Recommendation{} = user_recommendation) do
    Repo.delete(user_recommendation)
  end

  def paginate(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <-
           Filtrex.parse_params(
             filter_config(:user_recommendations),
             params["user_recommendation"] || %{}
           ),
         %Scrivener.Page{} = page <- do_paginate(filter, params) do
      {:ok,
       %{
         user_recommendations: page.entries,
         page_number: page.page_number,
         page_size: page.page_size,
         total_pages: page.total_pages,
         total_entries: page.total_entries,
         distance: @pagination_distance,
         sort_field: sort_field,
         sort_direction: sort_direction
       }}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp do_paginate(filter, params) do
    from(r in Recommendation,
      join: u in assoc(r, :user),
      preload: [user: u]
    )
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  defp filter_config(:user_recommendations) do
    defconfig do
      number(:id)
      number(:user_id)
      text(:type)
      datetime(:inserted_at)
    end
  end
end
