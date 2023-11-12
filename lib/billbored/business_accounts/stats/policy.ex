defmodule BillBored.BusinessAccounts.Stats.Policy do
  @moduledoc false
  alias BillBored.User.Membership
  import Ecto.Query

  @actions [:stats, :post_views, :post_stats]

  def authorize(action, %{"business_id" => business_id}, user_id) when action in @actions do
    Membership
    |> where([m], m.business_account_id == ^business_id and m.member_id == ^user_id)
    |> Repo.one()
    |> case do
      %Membership{} ->
        true

      nil ->
        {false, :missing_business_membership}
    end
  end
end
