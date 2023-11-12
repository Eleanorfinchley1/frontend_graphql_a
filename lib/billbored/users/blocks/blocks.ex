defmodule BillBored.User.Blocks do
  import Ecto.Query

  alias BillBored.User.Block
  alias BillBored.User

  def block(%User{}, %User{is_superuser: true}), do: {:error, :cannot_block_superuser}
  def block(%User{id: blocker_id}, %User{id: blocker_id}), do: {:error, :cannot_block_self}

  def block(%User{} = blocker, %User{} = blocked) do
    {:ok, %{insert_block: result}} =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:insert_block, fn repo, _ ->
        %Block{}
        |> Block.changeset(%{blocker: blocker, blocked: blocked})
        |> repo.insert()
      end)
      |> Ecto.Multi.run(:remove_followings, fn _repo, _ ->
        {:ok, BillBored.User.Followings.delete_between(blocker.id, blocked.id)}
      end)
      |> Ecto.Multi.run(:notify_channels, fn _repo, _ ->
        send_user_blocks_update(blocker.id)
        send_user_blocks_update(blocked.id)
        {:ok, nil}
      end)
      |> Repo.transaction()

    {:ok, result}
  end

  def unblock(%User{} = blocker, %User{} = blocked) do
    from(b in Block,
      where: b.to_userprofile_id == ^blocker.id and b.from_userprofile_id == ^blocked.id
    )
    |> Repo.delete_all()

    send_user_blocks_update(blocker.id)
    send_user_blocks_update(blocked.id)

    :ok
  end

  def get_blocked_by(%User{} = blocker) do
    from(u in User)
    |> join(:inner, [u, b], b in Block, on: u.id == b.from_userprofile_id)
    |> where([u, b], b.to_userprofile_id == ^blocker.id)
    |> Repo.all()
  end

  def get_blockers_of(%User{} = blocked) do
    from(u in User)
    |> join(:inner, [u, b], b in Block, on: u.id == b.to_userprofile_id)
    |> where([u, b], b.from_userprofile_id == ^blocked.id)
    |> Repo.all()
  end

  defp send_user_blocks_update(user_id) do
    Phoenix.PubSub.broadcast(
      Web.PubSub,
      "user_blocks:#{user_id}",
      {:user_blocks_update, %{id: user_id}}
    )
  end
end
