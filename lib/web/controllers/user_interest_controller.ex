# TODO: drop
defmodule Web.UserInterestController do
  use Web, :controller
  alias BillBored.{Interests, Users, User}

  action_fallback Web.FallbackController

  # TODO move query logic to context
  import Ecto.Query

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def list(conn, _params, user_id) do
    user =
      user_id
      |> Users.get!()
      |> Repo.preload([:interests_interest])

    json(conn, Phoenix.View.render_many(user.interests_interest, Web.InterestView, "show.json"))
  end

  def create(conn, %{"interest" => id}, user_id) do
    interest = Interests.get!(id)

    # TODO just rely on foreign_key_constraint in the changeset

    ui = User.Interest.changeset(%User.Interest{}, %{user_id: user_id, interest_id: interest.id})

    with {:ok, _user_interest} <- Repo.insert(ui) do
      send_resp(conn, 204, [])
    end
  end

  def delete(conn, %{"id" => interest_id}, user_id) do
    interest_id = String.to_integer(interest_id)

    User.Interest
    |> where(interest_id: ^interest_id)
    |> where(user_id: ^user_id)
    |> Repo.delete_all()

    send_resp(conn, 204, [])
  end
end
