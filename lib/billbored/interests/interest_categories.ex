defmodule BillBored.InterestCategories do
  import Ecto.Query

  alias BillBored.InterestCategory
  alias BillBored.User

  def list_all() do
    from(ic in InterestCategory,
      order_by: [asc: :name]
    )
    |> Repo.all()
  end

  def list_for_user(user_id) do
    from(ic in InterestCategory,
      distinct: true,
      join: ici in "interest_categories_interests",
      on: ici.interest_category_id == ic.id,
      join: ui in User.Interest,
      on: ui.interest_id == ici.interest_id and ui.user_id == ^user_id
    )
    |> Repo.all()
  end

  def validate(categories) when is_list(categories) do
    missing =
      "categories"
      |> with_cte("categories", as: fragment("SELECT * FROM UNNEST(?::text[]) name", ^categories))
      |> where([c], fragment("NOT EXISTS (SELECT TRUE FROM interest_categories ic WHERE ic.name = ?)", c.name))
      |> select([c], c.name)
      |> Repo.all()

    case missing do
      [] ->
        :ok

      _ ->
        {:error, :invalid_categories, Enum.join(missing, ", ")}
    end
  end

  def list(names) do
    from(ic in InterestCategory, where: ic.name in ^names)
    |> Repo.all()
  end
end
