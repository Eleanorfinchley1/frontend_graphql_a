defmodule Web.Torch.LocationRewardController do
  use Web, :controller

  alias BillBored.Torch.LocationRewardDecorator
  alias BillBored.Torch.LocationRewards, as: TorchLocationRewards

  plug(:put_layout, {Web.LayoutView, "torch.html"})

  def index(conn, params) do
    case TorchLocationRewards.paginate_location_rewards(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)

      error ->
        conn
        |> put_flash(:error, "There was an error rendering local rewards: #{inspect(error)}")
        |> redirect(to: Routes.torch_location_reward_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id}) do
    location_reward = TorchLocationRewards.get!(id)
    render(conn, "show.html", location_reward: location_reward)
  end

  def new(conn, _params) do
    changeset = LocationRewardDecorator.changeset(%LocationRewardDecorator{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"location_reward_decorator" => attrs} = _params) do
    with changeset <- LocationRewardDecorator.changeset(%LocationRewardDecorator{}, attrs),
         {:ok, decorator} <- Ecto.Changeset.apply_action(changeset, :create),
         {:ok, location_reward} <- TorchLocationRewards.create(decorator) do
      render(conn, "show.html", location_reward: location_reward)
    else
      {:error, %{valid?: false} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    location_reward = TorchLocationRewards.get!(id)
    with {:ok, _location_reward} <- TorchLocationRewards.delete(location_reward) do
      conn
      |> put_flash(:info, "Location reward #{id} deleted successfully.")
      |> redirect(to: Routes.torch_location_reward_path(conn, :index))
    else
      error ->
        conn
        |> put_flash(:error, "Failed to delete location reward #{id}: #{inspect(error)}")
        |> redirect(to: Routes.torch_location_reward_path(conn, :index))
    end
  end

  def pre_notify(conn, params) do
    with location_reward = TorchLocationRewards.get!(String.to_integer(params["location_reward_id"])),
         {:ok, assigns} <- TorchLocationRewards.paginate_users(params),
         has_blocks <- TorchLocationRewards.block_params?(params),
         custom_filters <- TorchLocationRewards.custom_filters(params) do
      render(conn, "notify.html", assigns |> Map.put(:has_blocks, has_blocks) |> Map.put(:custom_filters, custom_filters) |> Map.put(:location_reward, location_reward))
    else
      error ->
        conn
        |> put_flash(:error, "There was an error rendering Users. #{inspect(error)}")
        |> redirect(to: Routes.torch_location_reward_path(conn, :pre_notify))
    end
  end

  def notify(conn, params) do
    case TorchLocationRewards.notify_to_filtered_users(params) do
      {:ok, num_rows} ->
        conn
          |> put_flash(:info, "Notify to #{num_rows} users successfully.")
          |> redirect(to: Routes.torch_location_reward_path(conn, :pre_notify, params["location_reward_id"], params))
      {:error, error} ->
        conn
          |> put_flash(:error, "#{IO.inspect(error)}")
          |> redirect(to: Routes.torch_location_reward_path(conn, :pre_notify, params["location_reward_id"], params))
    end
  end
end
