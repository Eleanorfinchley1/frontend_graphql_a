defmodule BillBored.Notifications.AreaNotifications.Policy do
  import Ecto.Query

  alias BillBored.Notifications.AreaNotification
  alias BillBored.User.Membership

  def authorize(:create_business_area_notification, %{business_id: business_id}, user_id) do
    authorize_business_member(business_id, user_id, allow_roles: ["owner", "admin", "member"])
  end

  def authorize(
        :delete_business_area_notification,
        %AreaNotification{owner_id: owner_id, business_id: business_id},
        user_id
      ) do
    authorize_business_member(business_id, user_id, allow_roles: ["owner", "admin"], owner_id: owner_id)
  end

  def authorize(:list_business_area_notifications, %{business_id: business_id}, user_id) do
    authorize_business_member(business_id, user_id, allow_roles: ["owner", "admin", "member"])
  end

  defp authorize_business_member(business_id, member_id, opts)
       when not is_nil(business_id) and not is_nil(member_id) do
    Membership
    |> where([m], m.business_account_id == ^business_id and m.member_id == ^member_id)
    |> Repo.one()
    |> case do
      %Membership{role: role} ->
        if role in (opts[:allow_roles] || []) do
          true
        else
          if opts[:owner_id] == member_id, do: true, else: {false, :user_not_author}
        end

      nil ->
        {false, :missing_business_membership}
    end
  end
end
