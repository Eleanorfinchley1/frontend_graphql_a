defmodule BillBored.User.UserRecommendations do
  import Ecto.Query

  alias BillBored.User.Recommendation, as: UserRecommendation
  alias BillBored.User.Followings.Following

  def follow_autofollow_recommendations(user_id) do
    follow_user_ids =
      from(r in UserRecommendation,
        where: r.type == "autofollow",
        select: r.user_id
      )
      |> Repo.all()

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:insert_followings, fn _, _ ->
        utc_now = DateTime.utc_now()
        followings = Enum.map(follow_user_ids, fn follow_user_id ->
          %{
            to_userprofile_id: follow_user_id,
            from_userprofile_id: user_id,
            inserted_at: utc_now
          }
        end)

        {_, inserted} = Repo.insert_all(Following, followings, on_conflict: :nothing, returning: true)
        {:ok, inserted}
      end)
      |> Ecto.Multi.run(:update_user_flags, fn _, _ ->
        BillBored.Users.replace_flags(user_id, %{"autofollow" => "done"})
      end)
      |> Repo.transaction()

    with {:ok, %{upate_user_flags: updated_user}} <- result do
      {:ok, updated_user}
    end
  end
end
