defmodule BillBored.Invites do
  @moduledoc """
  The Invites context. This context describes how to use models and to build functions for future use.
  The official documentation is located at the following address [`Phoenix.Contexts`](https://hexdocs.pm/phoenix/contexts.html#content).

  The following models are available for use in the current context:

    alias BillBored.Invites.Invite

  To work with this schema, you need to use a dependency.

    # To build samples from the database you need to use
    import Ecto.Query, warn: false

  """

  import Ecto.Query

  def get_invite(id) do
    __MODULE__.Invite
    |> Repo.get(id)
  end

  def get_invites_by_user_id(user_id) do
    __MODULE__.Invite
    |> where([i], i.user_id == ^user_id)
    |> Repo.all()
  end

  def get_by_invites(params) do
    Repo.get_by(__MODULE__.Invite, params)
  end

  def create_invite(attrs \\ %{}) do
    %__MODULE__.Invite{}
    |> __MODULE__.Invite.changeset(attrs)
    |> Repo.insert()
  end

  def update_invite(%__MODULE__.Invite{} = invite, attrs) do
    invite
    |> __MODULE__.Invite.changeset(attrs)
    |> Repo.update()
  end

  def delete_invite(id) do
    case get_invite(id) do
      %__MODULE__.Invite{} = invite ->
        Repo.delete(invite)

      nil ->
        {:error, "Not found."}
    end
  end
end
