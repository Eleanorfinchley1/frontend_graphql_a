defmodule Web.Torch.UserController do
  use Web, :controller

  alias BillBored.User
  alias BillBored.Torch.Users, as: TorchUsers

  plug(:put_layout, {Web.LayoutView, "torch.html"})

  def index(conn, params) do
    with {:ok, assigns} <- TorchUsers.paginate_users(params),
         has_blocks <- TorchUsers.block_params?(params),
         custom_filters <- TorchUsers.custom_filters(params) do
      render(conn, "index.html", assigns |> Map.put(:has_blocks, has_blocks) |> Map.put(:custom_filters, custom_filters))
    else
      error ->
        conn
        |> put_flash(:error, "There was an error rendering Users. #{inspect(error)}")
        |> redirect(to: Routes.torch_user_path(conn, :index))
    end
  end

  def index_with_activities(conn, params) do
    pagination_result = TorchUsers.list_users_with_activities(params)
    render(conn, "index_with_activities.json", pagination_result)
  end

  def show(conn, %{"id" => id}) do
    user = TorchUsers.get_user!(id)
    render(conn, "show.html", user: user)
  end

  def ban_user(conn, %{"id" => id}) do
    update_action(conn, id, "Ban user", fn ->
      TorchUsers.get_user!(id)
      |> User.admin_changeset(%{banned?: true})
      |> Repo.update()
    end)
  end

  def unban_user(conn, %{"id" => id}) do
    update_action(conn, id, "Unban user", fn ->
      TorchUsers.get_user!(id)
      |> User.admin_changeset(%{banned?: false})
      |> Repo.update()
    end)
  end

  def restrict_access(conn, %{"id" => id}) do
    update_action(conn, id, "Restrict access", fn ->
      user = TorchUsers.get_user!(id)
      User.admin_changeset(user, %{flags: Map.merge(user.flags, %{
        "access" => "restricted",
        "restriction_reason" => "Thank you for your interest in the service. We will invite you in as soon as more room is available!"
      })})
      |> Repo.update()
    end)
  end

  def grant_access(conn, %{"id" => id}) do
    update_action(conn, id, "Grant access", fn ->
      user = TorchUsers.get_user!(id)
      if user.flags["access"] != "granted" do
        new_flags =
          user.flags
          |> Map.drop(["restriction_reason"])
          |> Map.merge(%{"access" => "granted"})

        with {:ok, updated_user} <- User.admin_changeset(user, %{flags: new_flags}) |> Repo.update() do
          Notifications.process_user_access_granted(updated_user |> Repo.preload(:devices))
          {:ok, updated_user}
        end
      else
        {:ok, user}
      end
    end)
  end

  defp update_action(conn, id, action, fun) do
    with {:ok, _} <- fun.() do
      conn
      |> put_flash(:info, "#{action}: success")
      |> redirect(to: Routes.torch_user_path(conn, :show, id))
    else
      error ->
        conn
        |> put_flash(:error, "#{action} failed: #{inspect(error)}")
        |> redirect(to: Routes.torch_user_path(conn, :show, id))
    end
  end
end
