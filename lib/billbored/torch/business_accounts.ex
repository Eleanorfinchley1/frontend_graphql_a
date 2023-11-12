defmodule BillBored.Torch.BusinessAccounts do
  @moduledoc """
  The Torch context.
  """

  import Ecto.Query, warn: false

  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  alias BillBored.User

  @pagination [page_size: 15]
  @pagination_distance 5

  def paginate_business_accounts(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "date_joined")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <- Filtrex.parse_params(filter_config(:business_accounts), params["user"] || %{}),
         %Scrivener.Page{} = page <- do_paginate_users(filter, params) do
      {:ok,
        %{
          business_accounts: page.entries,
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

  defp do_paginate_users(filter, params) do
    User
    |> where([u], u.is_business == true)
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  def get_business_account!(id) do
    User
    |> where([u], u.is_business == true and u.id == ^id)
    |> preload([u], :business_suggestion)
    |> Repo.one!()
  end

  def update_business_account(business_account, attrs) do
    Ecto.Changeset.change(business_account)
    |> Ecto.Changeset.cast(attrs, [])
    |> Ecto.Changeset.cast_assoc(:business_suggestion)
    |> Repo.update()
  end

  defp filter_config(:business_accounts) do
    defconfig do
      number(:id)
      text(:username)
      text(:first_name)
      text(:last_name)
      text(:email)
    end
  end
end
