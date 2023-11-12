defmodule BillBored.Chat.Room.ElevatedPrivileges do
  alias BillBored.{Chat, User}
  alias Chat.{Room, Rooms}
  alias Room.ElevatedPrivilege
  alias Ecto.Multi

  def grant(request_id, by: admin_id) do
    Multi.new()
    |> Multi.run(:request, fn _repo, _changes ->
      case get_request(request_id) do
        %ElevatedPrivilege.Request{} = request -> {:ok, request}
        nil -> {:error, :not_found}
      end
    end)
    |> Multi.run(:admin?, fn _repo, %{request: %ElevatedPrivilege.Request{room_id: room_id}} ->
      case Rooms.admin?(room_id: room_id, user_id: admin_id) do
        true -> {:ok, true}
        false -> {:error, false}
      end
    end)
    |> Multi.run(:granted_privilege, fn repo,
                                        %{
                                          request: %ElevatedPrivilege.Request{
                                            room_id: dropchat_id,
                                            userprofile_id: requester_id
                                          }
                                        } ->
      repo.insert(%ElevatedPrivilege{dropchat_id: dropchat_id, user_id: requester_id}, on_conflict: :nothing)
    end)
    |> Multi.run(:notifications, fn repo,
                                    %{granted_privilege: %ElevatedPrivilege{} = granted_privilege} ->
      granted_privilege = repo.preload(granted_privilege, [:dropchat, user: :devices])
      Notifications.process_dropchat_privilege_granted(granted_privilege)
      {:ok, nil}
    end)
    |> Multi.run(:cleanup, fn repo, %{request: %ElevatedPrivilege.Request{} = request} ->
      repo.delete(request)
    end)
    |> Repo.transaction()
  end

  @spec maybe_create(Chat.Room.t(), User.t()) :: boolean
  def maybe_create(%Chat.Room{} = dropchat, %User{} = user) do
    # TODO use on conflict
    Repo.insert!(%ElevatedPrivilege{user: user, dropchat: dropchat})
    true
  rescue
    _ -> false
  end

  @spec get_request(pos_integer) :: ElevatedPrivilege.Request.t() | nil
  def get_request(request_id) do
    Repo.get(ElevatedPrivilege.Request, request_id)
  end
end
