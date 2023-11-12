defmodule Web.Torch.InterestCategoryController do
  use Web, :controller

  import Ecto.Query

  alias BillBored.InterestCategory
  alias BillBored.Torch.InterestCategoryDecorator
  alias BillBored.Torch.InterestCategories, as: TorchInterestCategories

  plug(:put_layout, {Web.LayoutView, "torch.html"})

  def index(conn, params) do
    with {:ok, assigns} <- TorchInterestCategories.paginate(params) do
      render(conn, "index.html", assigns)
    else
      error ->
        conn
        |> put_flash(:error, "An error occured while rendering page: #{inspect(error)}")
        |> redirect(to: Routes.torch_interest_category_path(conn, :index))
    end
  end

  def new(conn, _params) do
    render(conn, "new.html", changeset: InterestCategoryDecorator.changeset(%InterestCategory{}))
  end

  def create(conn, %{"interest_category_decorator" => attrs} = _params) do
    with changeset <- InterestCategoryDecorator.changeset(%InterestCategory{}, attrs),
         {:ok, decorator} <- Ecto.Changeset.apply_action(changeset, :create),
         {:ok, decorator} <- upsert_decorator_interests(decorator),
         changeset <- InterestCategory.changeset(%InterestCategory{}, Map.from_struct(decorator)),
         {:ok, interest_category} <- Repo.insert(changeset) do
      render(conn, "show.html", interest_category: interest_category)
    else
      {:error, %{valid?: false} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    interest_category = TorchInterestCategories.get(id)
    render(conn, "show.html", interest_category: interest_category)
  end

  def edit(conn, %{"id" => id}) do
    interest_category = TorchInterestCategories.get(id)
    render(conn, "edit.html", interest_category: interest_category, changeset: InterestCategoryDecorator.update_changeset(interest_category))
  end

  def update(conn, %{"id" => id, "interest_category_decorator" => attrs} = _params) do
    interest_category = TorchInterestCategories.get(id)
    with changeset <- InterestCategoryDecorator.update_changeset(interest_category, attrs),
         {:ok, decorator} <- Ecto.Changeset.apply_action(changeset, :update),
         {:ok, decorator} <- upsert_decorator_interests(decorator),
         changeset <- InterestCategory.changeset(interest_category, Map.from_struct(decorator)),
         {:ok, interest_category} <- Repo.update(changeset) do
      render(conn, "show.html", interest_category: interest_category)
    else
      {:error, %{valid?: false} = changeset} ->
        render(conn, "edit.html", interest_category: interest_category, changeset: changeset)
    end
  end

  defp upsert_decorator_interests(%InterestCategoryDecorator{interests: interests} = decorator) do
    now = DateTime.utc_now()

    interests_to_insert =
      interests
      |> Enum.map(fn %{hashtag: hashtag, icon: icon} = interest ->
        %{
          hashtag: hashtag,
          icon: icon,
          inserted_at: interest.inserted_at || now
        }
      end)

    Repo.transaction(fn _ ->
      {_, _updated_interests} =
        Repo.insert_all(
          BillBored.Interest,
          interests_to_insert,
          returning: [:hashtag],
          conflict_target: [:hashtag],
          on_conflict: {:replace, [:icon]}
        )

      hashtags = Enum.map(interests, fn %{hashtag: hashtag} -> hashtag end)
      new_interests =
        from(i in BillBored.Interest, where: i.hashtag in ^hashtags)
        |> Repo.all()

      %InterestCategoryDecorator{decorator | interests: new_interests}
    end)
  end

  def delete(conn, %{"id" => id}) do
    interest_category = TorchInterestCategories.get(id)
    with {:ok, _interest_category} <- TorchInterestCategories.delete(interest_category) do
      conn
      |> put_flash(:info, "Interest Category #{id} deleted successfully.")
      |> redirect(to: Routes.torch_interest_category_path(conn, :index))
    else
      error ->
        conn
        |> put_flash(:error, "Failed to delete Interest Category #{id}: #{inspect(error)}")
        |> redirect(to: Routes.torch_interest_category_path(conn, :index))
    end
  end
end