defmodule Web.UserView do
  use Web, :view

  alias BillBored.{User, User.Membership}
  alias Web.ViewHelpers

  @account_levels ["Mentee", "Mentor", "Don", "Legend"]

  defp signed(user, field) do
    case picture = Map.get(user, field) do
      "http" <> _ -> picture
      "" -> picture
      _ ->
        expires_at = :os.system_time(:seconds) + 10 * 60 * 60
        Signer.create_signed_url(
          "GET",
          expires_at,
          "/#{System.get_env("GS_MEDIA_BUCKET_NAME")}/#{picture}"
        )
    end
  end

  def render("user.json", %{user: user}) do
    render("min.json", %{user: user})
  end

  if Mix.env() == :test do
    def render("min.json", %{user: user}) do
      fields = [:id, :username, :first_name, :last_name, :is_ghost]

      payload = user
        |> Map.take(fields ++ [:avatar, :avatar_thumbnail])

      if user && Ecto.assoc_loaded?(user) do
        payload = if user.points && Ecto.assoc_loaded?(user.points) do
          Map.put(payload, :user_points, Web.UserPointView.render("show.json", %{user: user}))
        else
          payload
        end

        payload = if user.university && Ecto.assoc_loaded?(user.university) do
          Map.put(payload, :university, Web.UniversityView.render("university.json", %{university: user.university}))
        else
          payload
        end

        payload = if is_nil(user) || is_nil(user.total_points) do
          payload
        else
          Map.put(payload, :total_points, user.total_points / 10)
        end

        payload = if is_nil(user) || is_nil(user.semester_points) do
          payload
        else
          Map.put(payload, :semester_points, user.semester_points / 10)
        end

        payload = if is_nil(user) || is_nil(user.monthly_points) do
          payload
        else
          Map.put(payload, :monthly_points, user.monthly_points / 10)
        end

        payload = if is_nil(user) || is_nil(user.weekly_points) do
          payload
        else
          Map.put(payload, :weekly_points, user.weekly_points / 10)
        end

        payload = if is_nil(user) || is_nil(user.daily_points) do
          payload
        else
          Map.put(payload, :daily_points, user.daily_points / 10)
        end
      else
        payload
      end
    end
  else
    def render("min.json", %{user: user}) do
      fields = [:id, :username, :first_name, :last_name, :is_ghost]

      payload = user
        |> Map.take(fields)
        |> Map.put(:avatar, signed(user, :avatar))
        |> Map.put(:avatar_thumbnail, signed(user, :avatar_thumbnail))

      if user && Ecto.assoc_loaded?(user) do
        payload = if user.points && Ecto.assoc_loaded?(user.points) do
          Map.put(payload, :user_points, Web.UserPointView.render("show.json", %{user: user}))
        else
          payload
        end

        payload = if user.university && Ecto.assoc_loaded?(user.university) do
          Map.put(payload, :university, Web.UniversityView.render("university.json", %{university: user.university}))
        else
          payload
        end

        payload = if is_nil(user) || is_nil(user.total_points) do
          payload
        else
          Map.put(payload, :total_points, user.total_points / 10)
        end

        payload = if is_nil(user) || is_nil(user.semester_points) do
          payload
        else
          Map.put(payload, :semester_points, user.semester_points / 10)
        end

        payload = if is_nil(user) || is_nil(user.monthly_points) do
          payload
        else
          Map.put(payload, :monthly_points, user.monthly_points / 10)
        end

        payload = if is_nil(user) || is_nil(user.weekly_points) do
          payload
        else
          Map.put(payload, :weekly_points, user.weekly_points / 10)
        end

        if is_nil(user) || is_nil(user.daily_points) do
          payload
        else
          Map.put(payload, :daily_points, user.daily_points / 10)
        end
      else
        payload
      end
    end
  end

  def render("show.json", %{user: user}) do
    render("custom_user.json", %{user: user})
  end

  def render("full_user.json", %{user: user}) do
    render("custom_user.json", %{user: user})
  end

  def render("custom_user.json", %{user: user}) do
    real_location =
      if user.user_real_location != "" do
        user.user_real_location
      end

    safe_location =
      if user.user_safe_location != "" do
        user.user_safe_location
      end

    user_tags = if Ecto.assoc_loaded?(user.interests_interest) && user.interests_interest != nil do
      render_many(user.interests_interest, Web.InterestView, "show.json")
    else
      []
    end

    user_points = Web.UserPointView.render("show.json", %{user: user})
    reactions = Web.SpeakerReactionView.render("show.json", %{speaker_id: user.id})

    payload = %{
      "id" => user.id,
      "username" => user.username,
      "user_tags" => user_tags,
      "user_points" => user_points,
      "email" => user.email,
      "first_name" => user.first_name,
      "last_name" => user.last_name,
      "university_id" => user.university_id,
      "date_joined" => user.date_joined,
      "avatar" => signed(user, :avatar),
      "avatar_thumbnail" => signed(user, :avatar_thumbnail),
      "country_code" => user.country_code,
      "phone" => user.phone,
      "verified_phone" => user.verified_phone,
      "bio" => user.bio,
      "sex" => user.sex,
      "referral_code" => user.referral_code,
      "birthdate" => user.birthdate,
      "user_real_location" => render_one(real_location, Web.LocationView, "show.json"),
      "user_safe_location" => render_one(safe_location, Web.LocationView, "show.json"),
      "area" => user.area,
      "prefered_radius" => user.prefered_radius,
      "reactions" => reactions,
      "enable_push_notifications" => user.enable_push_notifications,
      "last_online_at" => user.last_online_at,
      "is_follower" => user.is_follower,
      "is_following" => user.is_following
    }

    payload = if Ecto.assoc_loaded?(user.mentor) do
      Map.merge(payload, %{
        "account_level" => (user.mentor || %{level: 0}).level,
        "account_level_description" => Enum.at(@account_levels, (user.mentor || %{level: 0}).level)
      })
    else
      payload
    end

    payload = if Ecto.assoc_loaded?(user.mentee_mentor) && user.mentee_mentor != nil do
      Map.put(payload, "mentor", render("custom_user.json", %{user: user.mentee_mentor}))
    else
      payload
    end

    if Ecto.assoc_loaded?(user.university) && user.university != nil do
      Map.put(payload, "university", Web.UniversityView.render("university.json", %{university: user.university}))
    else
      payload
    end
  end

  def render("business_account.json", %{user: user}) do
    location = if user.user_real_location != "", do: user.user_real_location

    %{
      "id" => user.id,
      "business_account_name" => user.first_name,
      "avatar" => signed(user, :avatar) || "",
      "avatar_thumbnail" => signed(user, :avatar_thumbnail) || "",
      "business_account_user_name" => user.username,
      "last_name" => user.last_name,
      "email" => user.email,
      "location" => render_one(location, Web.LocationView, "show.json"),
      "categories" =>
        Web.BusinessView.render(
          "categories.json",
          categories: user.business_category
        ),
      "followers_count" => user.followers_count || 0,
      "suggestion" => if Ecto.assoc_loaded?(user.business_suggestion) && user.business_suggestion do
        user.business_suggestion.suggestion
      end
    }
  end

  def render(
        "member_of.json",
        %{
          member: %Membership{
            id: id,
            role: role,
            member: member
          }
        }
      ) do
    %{
      "id" => id,
      "username" => member.username,
      "avatar" => signed(member, :avatar),
      "avatar_thumbnail" => signed(member, :avatar_thumbnail),
      "first_name" => member.first_name,
      "last_name" => member.last_name,
      "role" => role
    }
  end

  def render("members_of.json", %{members: members}) do
    Enum.map(
      members,
      fn %Membership{} = member ->
        render("member_of.json", %{member: member})
      end
    )
  end

  def render("business_accounts.json", %{users: users}) do
    Enum.map(
      users,
      fn %User{} = user ->
        render("business_account.json", %{user: user})
      end
    )
  end

  def render("list.json", %{users: users}) do
    render_many(users, Web.UserView, "min.json")
  end

  def render("index.json", %{conn: conn, data: users}) do
    ViewHelpers.index(conn, users, __MODULE__, "min.json")
  end

  def render("profiles_search.json", %{
        search_term: search_term,
        fields: fields,
        results: results
      }) do
    if Enum.all?(fields, fn field -> length(results[field]) == 0 end) do
      []
    else
      Enum.map(fields, fn field ->
        render("profiles_search.json", %{
          search_term: search_term,
          field: field,
          users: results[field]
        })
      end)
    end
  end

  def render("profiles_search.json", %{
        search_term: search_term,
        field: field,
        users: users
      }) do
    users_as_array_of_map =
      if users == nil || length(users) == 0 do
        []
      else
        Enum.map(
          users,
          fn %User{} = user ->
            # render("user.json", %{user: user})
            %{
              "username" => user.username,
              "email" => user.email,
              "first_name" => user.first_name,
              "last_name" => user.last_name,
              "date_joined" => user.date_joined,
              "avatar" => user.avatar,
              "avatar_thumbnail" => user.avatar_thumbnail,
              "country_code" => user.country_code,
              "phone" => user.phone
            }
          end
        )
      end

    %{
      "search_term" => search_term,
      "field" => field,
      "results" => users_as_array_of_map
    }
  end
end
