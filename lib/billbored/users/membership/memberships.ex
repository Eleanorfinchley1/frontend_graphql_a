defmodule BillBored.User.Memberships do
  import Ecto.Query
  alias BillBored.{User.Membership, User}

  def get(account, member) do
    Membership
    |> where([m], m.business_account_id == ^account.id and m.member_id == ^member.id)
    |> first
    |> Repo.one()
  end

  def members_of(account) do
    Membership
    |> join(:inner, [m], u in User,
      on: u.id == m.member_id and m.business_account_id == ^account.id
    )
    |> preload([:member, :business_account])
    |> Repo.all()
  end

  def admins_of(account) do
    Membership
    |> where(
      [m],
      fragment("lower(?)", m.role) == "admin" or fragment("lower(?)", m.role) == "owner"
    )
    |> join(:inner, [m], u in User,
      on: u.id == m.member_id and m.business_account_id == ^account.id
    )
    |> preload([:member, :business_account])
    |> Repo.all()
  end

  def membership_of(account) do
    Membership
    |> where([m], m.business_account_id == ^account.id)
    |> Repo.all()
    |> Repo.preload([:member, :business_account])
  end

  def get_by_member_id(account, member_id) do
    Membership
    |> where([m], m.business_account_id == ^account.id and m.member_id == ^member_id)
    |> Repo.one()
    |> Repo.preload([:member, :business_account])
  end

  def business_accounts_of(user) do
    Membership
    |> where([m], m.member_id == ^user.id)
    |> Repo.all()
    |> Repo.preload([:member, :business_account])
  end

  def add_member(account, member, role) do
    if account == nil do
      %{"status" => 404, "message" => "Business account not found!"}
    else
      if member == nil do
        %{"status" => 404, "message" => "User not found!"}
      else
        attrs = %{business_account_id: account.id, member_id: member.id, role: role}

        %Membership{}
        |> Membership.changeset(attrs)
        |> Repo.insert()
      end
    end
  end

  def remove_member(account, member) do
    Membership
    |> where([m], m.business_account_id == ^account.id and m.member_id == ^member.id)
    |> Repo.delete_all()
  end

  def delete_personal_owner_account(member) do
    Membership
    |> where([m], m.member_id == ^member.id)
    |> Repo.delete_all()
  end

  def delete_business_account(business_account) do
    Membership
    |> where([m], m.business_account_id == ^business_account.id)
    |> Repo.delete_all()
  end

  def update_role(account, member, role) do
    attrs = %{role: role}

    get(account, member)
    |> Membership.changeset(attrs)
    |> Repo.update()
  end
end
