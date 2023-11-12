defmodule BillBored.Posts.Policy do
  @moduledoc false
  alias BillBored.{Post, Users, User.Membership}
  import Ecto.Query

  @spec authorize(:create_post, map, pos_integer) :: boolean | {false, String.t()}
  def authorize(:create_post, params, user_id) do
    if params["is_business"] || params["type"] == "offer" do
      business_username =
        params["business_username"] || raise("missing business_username in #{inspect(params)}")

      business_account =
        Users.get_by_username(business_username) ||
          raise("non existent business: #{inspect(business_username)}")

      Membership
      |> where([m], m.business_account_id == ^business_account.id and m.member_id == ^user_id)
      |> Repo.one()
      |> case do
        %Membership{role: "owner"} -> true
        %Membership{required_approval: false} -> true
        %Membership{role: role} when role in ["admin", "member"] -> {false, "Approval required"}
        nil -> false
      end
    else
      true
    end
  end

  def authorize(
        action,
        %Post{type: "offer", business_id: business_id, author_id: author_id},
        user_id
      )
      when action in [:delete_post, :update_post] and not is_nil(business_id) and not is_nil(author_id) do
    Membership
    |> where([m], m.business_account_id == ^business_id and m.member_id == ^user_id)
    |> Repo.one()
    |> case do
      %Membership{role: role} when role in ["owner", "admin"] ->
        true

      %Membership{} ->
        if author_id == user_id do
          true
        else
          {false, :user_not_author}
        end

      nil ->
        {false, :missing_business_membership}
    end
  end

  def authorize(action, %Post{author_id: author_id}, user_id) when action in [:delete_post, :update_post] do
    if author_id == user_id do
      true
    else
      {false, :user_not_author}
    end
  end
end
