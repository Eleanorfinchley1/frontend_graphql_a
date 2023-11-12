defmodule BillBored.BusinessCategories do
  @moduledoc ""

  import Ecto.Query
  alias BillBored.{BusinessCategory, BusinessesCategories}

  def create(attrs) do
    %BusinessCategory{}
    |> BusinessCategory.changeset(attrs)
    |> Repo.insert()
  end

  def all_business_accounts(last_seen_param, direction_param) do
    query =
      from(
        u in BusinessCategory,
        order_by: [asc: :id]
      )

    query = Ecto.CursorPagination.paginate(query, last_seen_param, direction_param)
    Repo.all(query)
  end

  def check_business_category_in_account(category_id, user_id) do
    BusinessesCategories
    |> where([bctg], bctg.business_category_id == ^category_id and bctg.user_id == ^user_id)
    |> first
    |> Repo.one()
  end

  def add_category_to_business(category) do
    {:ok, _inserted} = Repo.insert(category)
  end
end
