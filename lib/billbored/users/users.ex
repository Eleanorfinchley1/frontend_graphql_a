defmodule BillBored.Users do
  import Ecto.Query
  import Bcrypt, only: [verify_pass: 2]
  import BillBored.ServiceRegistry, only: [service: 1]

  alias BillBored.Users.PhoneVerification, as: PhoneVerificationModel
  alias BillBored.{User, User.AuthTokens, User.Memberships}
  alias BillBored.User.Followings.Following
  alias BillBored.User.UserRecommendations
  alias BillBored.UserPoint

  @spec get(any) :: User.t() | nil
  def get(user_id) do
    Repo.get(User, user_id)
  end

  @spec get!(any) :: User.t()
  def get!(user_id) do
    Repo.get!(User, user_id)
  end

  def get_user_profile(user_name, params \\ %{}) do
    User.available(params)
    |> where(username: ^user_name)
    |> with_followings(params)
    |> preload([
      :interests_interest,
      :mentor,
      :university
    ])
    |> Repo.one()
  end

  defp with_followings(query, %{for_id: for_id}) do
    query
    |> join(:left, [u, _], ff in Following, on: ff.from_userprofile_id == ^for_id and ff.to_userprofile_id == u.id, as: :ff)
    |> join(:left, [u, _], ft in Following, on: ft.to_userprofile_id == ^for_id and ft.from_userprofile_id == u.id, as: :ft)
    |> select_merge([u, ff: ff, ft: ft], %{
      is_follower: fragment("COALESCE(?, 0)::boolean", ft.id),
      is_following: fragment("COALESCE(?, 0)::boolean", ff.id)
    })
  end

  defp with_followings(query, _), do: query

  def get_user_profile!(user_name, params \\ %{}) do
    User.available(params)
    |> where(username: ^user_name)
    |> with_followings(params)
    |> preload([
      :interests_interest,
      :mentor,
      :university
    ])
    |> Repo.one!()
  end

  def list_users_located_around_location(%BillBored.Geo.Point{} = location) do
    import Geo.PostGIS, only: [st_distance_in_meters: 2]

    User
    |> where(
      [u],
      st_distance_in_meters(u.user_real_location, ^location) <
        fragment("? * 1000", u.prefered_radius)
    )
    |> Repo.all()
  end

  def list() do
    User
    |> where([u], u.banned? == false)
    |> where([u], u.deleted? == false)
    |> where([u], is_nil(u.event_provider))
    |> preload(:university)
    |> Repo.all()
  end

  def get_by_username(username) do
    User
    |> where([u], fragment("lower(?)", u.username) == ^String.downcase(username))
    |> first()
    |> preload([
      :business_category,
      :business_accounts,
      :members,
      business_accounts: :business_category
    ])
    |> Repo.one()
  end

  def get_by_email(email) do
    User
    |> where([u], u.email == ^email)
    |> first()
    |> Repo.one()
  end

  def send_email_verification(user) do
    alias Web.Router.Helpers, as: Routes

    token = Phoenix.Token.sign(Web.Endpoint, "user", user.id)
    # token = AuthTokens.generate(user)
    verification_url =
      Routes.account_url(Web.Endpoint, :email_verification, token: token, email: user.email)

    Mail.email_verification(user.email, %{url: verification_url})

    user
    |> Ecto.Changeset.change(%{verified_email: token})
    |> Repo.update()
  end

  def get_users_id_by_username(usernames) do
    User
    |> where([u], u.username in ^usernames)
    |> select([u], u.id)
    |> Repo.all()
  end

  def get_by(params) do
    Repo.get_by(User, params)
  end

  def get_by!(params) do
    Repo.get_by!(User, params)
  end

  def get_by_id(id) do
    User
    |> where([u], u.id == ^id)
    |> preload([
      :interests_interest,
      :business_category,
      :business_accounts,
      :members,
      :mentor,
      :mentee_mentor,
      :university,
      business_accounts: :business_category
    ])
    |> Repo.one()
  end

  def get_by_id!(id) do
    User
    |> where([u], u.id == ^id)
    |> preload([
      :interests_interest,
      :business_category,
      :business_accounts,
      :members,
      :mentor,
      :mentee_mentor,
      :university,
      business_accounts: :business_category
    ])
    |> Repo.one!()
  end

  def get_by_first_name(first_name) do
    User
    |> where([u], u.first_name == ^first_name)
    |> first()
    |> Repo.one()
  end

  def get_with_university_and_points(user_id) do
    user = User
    |> where([u], u.id == ^user_id)
    |> preload([:university, :points])
    |> Repo.one()
    if is_nil(user.points) do
      Map.put(user, :points, %UserPoint{stream_points: 0, general_points: 0})
    else
      user
    end
  end

  def users_count do
    User
    |> where([u], is_nil(u.event_provider))
    |> select([u], count(u.id))
    |> Repo.one()
  end

  @spec all([user_id :: pos_integer]) :: [User.t()]
  def all(user_ids) do
    User
    |> where([u], u.id in ^user_ids)
    |> Repo.all()
  end

  def all do
    Repo.all(User)
  end

  # TODO: use scrivner_ecto
  def all_business_accounts(last_seen_param, direction_param) do
    query =
      from(
        u in User,
        where: u.is_business == true,
        order_by: [asc: :id]
      )

    query = Ecto.CursorPagination.paginate(query, last_seen_param, direction_param)

    User
    |> preload(:business_category)

    Repo.all(query)
  end

  # TODO: use scrivner_ecto
  def all_users_accounts(last_seen_param, direction_param, params \\ %{}) do
    query =
      from(
        u in User.available(params),
        where: u.is_business == false,
        order_by: [asc: :id]
      )

    query = Ecto.CursorPagination.paginate(query, last_seen_param, direction_param)
    Repo.all(query)
  end

  defp preload_user(user_or_users, fields) do
    Repo.preload(user_or_users, fields)
  end

  def preload_devices(user_or_users) do
    preload_user(user_or_users, :devices)
  end

  def preload_user_tags(user_or_users) do
    preload_user(user_or_users, :interests_interest)
  end

  @spec user_followings_ids(pos_integer) :: [pos_integer]
  def user_followings_ids(user_id) do
    Following
    # we follow
    |> where([f_from], f_from.from_userprofile_id == ^user_id)
    |> select([f_from], f_from.to_userprofile_id)
    |> Repo.all()
  end

  # TODO isn't is more efficient than the below approach in list_friend_ids/1?
  # def followed_followers(user_id) do
  #   following = where(Following, from_userprofile_id: ^user_id)

  #   Following
  #   |> where(to_userprofile_id: ^user_id)
  #   |> join(:inner, [f], ff in subquery(following),
  #     on: f.from_userprofile_id == ff.to_userprofile_id
  #   )
  #   |> select([f, ff], f.from_userprofile_id)
  #   |> Repo.all()
  # end

  @spec list_friend_ids(pos_integer) :: [pos_integer]
  def list_friend_ids(user_id) do
    # TODO filter out blocked friends once that fature is added to the app

    User
    # we
    |> where(id: ^user_id)
    # follow and
    |> join(:inner, [u], f_from in Following, on: u.id == f_from.from_userprofile_id)
    # are followed
    |> join(:inner, [u, f_from], f_to in Following, on: u.id == f_to.to_userprofile_id)
    # by the same people
    |> where([u, f_from, f_to], f_from.to_userprofile_id == f_to.from_userprofile_id)
    # can also select f_to.from_userprofile_id
    |> select([u, f_from, f_to], f_from.to_userprofile_id)
    |> Repo.all()
  end

  @spec list_fellow_ids(pos_integer) :: [pos_integer]
  def list_fellow_ids(user_id) do
    user = get(user_id)
    # TODO filter out blocked friends once that fature is added to the app
    query = User |> where([u], u.id != ^user_id)
    query = if not is_nil(user.university_id) do
        query |> where([u], u.university_id == ^user.university_id)
      else
        query
      end
    query
    |> select([u], u.id)
    |> Repo.all()
  end

  @spec list_friends(pos_integer) :: [%User{}]
  def list_friends(user_id) do
    User
    |> where([u], u.id != ^user_id)
    |> join(:inner, [u], f_from in Following, on: u.id == f_from.from_userprofile_id)
    |> join(:inner, [u, f_from], f_to in Following, on: u.id == f_to.to_userprofile_id)
    |> where([u, f_from, f_to], f_from.to_userprofile_id == f_to.from_userprofile_id)
    |> Repo.all()
  end

  @spec list_followers(pos_integer) :: [%User{}]
  def list_followers(user_id, params \\ %{}) do
    User.available(params)
    |> join(:inner, [u], f in Following, on: u.id == f.from_userprofile_id)
    |> where([u, f], f.to_userprofile_id == ^user_id)
    |> Repo.all()
  end

  def top_followers(user_id, limit, params \\ %{}) do
    User.available(params)
    |> join(:inner, [u], f in Following, on: u.id == f.from_userprofile_id)
    |> where([u, f], f.to_userprofile_id == ^user_id)
    |> limit(^limit)
    |> Repo.all()
  end

  def business_followers_count(business_id) do
    User
    |> join(:inner, [u], f in Following, on: u.id == f.from_userprofile_id)
    |> where([u, f], f.to_userprofile_id == ^business_id)
    |> Repo.aggregate(:count)
  end

  def business_followers_history(business_id) do
    from(f in Following,
      where: f.to_userprofile_id == ^business_id,
      select: %{
        date: fragment("date_trunc('day', ? at time zone 'utc')::date", f.inserted_at),
        count: count(f)
      },
      group_by: fragment("date_trunc('day', ? at time zone 'utc')::date", f.inserted_at),
      order_by: [asc: fragment("date_trunc('day', ? at time zone 'utc')::date", f.inserted_at)]
    )
    |> Repo.all()
  end

  def index_friends(user_id, params) do
    import Ecto.Query

    User
    |> where([u], u.id != ^user_id)
    |> join(:inner, [u], f_from in Following, on: u.id == f_from.from_userprofile_id)
    |> join(:inner, [u, f_from], f_to in Following, on: u.id == f_to.to_userprofile_id)
    |> where(
      [u, f_from, f_to],
      f_from.to_userprofile_id == f_to.from_userprofile_id and
        f_from.to_userprofile_id == ^user_id
    )
    |> Repo.paginate(params)
  end

  def create_or_update_user(nickname, attrs) do
    case get_user_profile(nickname) do
      %User{} = user -> update_user(user, attrs)
      _ -> create(attrs)
    end
  end

  def create(attrs \\ %{}) do
    %User{}
    |> User.create_changeset(attrs)
    |> User.validate_phone()
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs \\ %{}) do
    user
    |> User.update_changeset(attrs)
    |> User.validate_phone()
    |> Repo.update()
  end

  def index_user_feedbacks(params) do
    import Ecto.Query

    User.Feedback
    |> Ecto.Query.preload([:feedback, :user])
    |> Ecto.Query.select([uf], uf)
    |> Repo.paginate(params)
  end

  def get_user_feedback!(params) do
    Repo.get_by!(User.Feedback, params)
  end

  def get_user_feedback(params) do
    Repo.get_by(User.Feedback, params)
  end

  def create_or_update_user_feedback(id, attrs) do
    get_user_feedback(feedback_ptr_id: id)
    |> case do
      %User.Feedback{} = user_feedback -> update_user_feedback(user_feedback, attrs)
      _ -> create_user_feedback(attrs)
    end
  end

  def create_user_feedback(attrs \\ %{}) do
    {:ok, feedback} = BillBored.Feedbacks.create_feedback(attrs)
    attrs = Map.put(attrs, "feedback_ptr_id", feedback.id)

    %User.Feedback{}
    |> User.Feedback.changeset(attrs)
    |> Repo.insert()
  end

  def update_user_feedback(%User.Feedback{} = user_feedback, attrs \\ %{}) do
    user_feedback
    |> User.Feedback.changeset(attrs)
    |> Repo.update()
  end

  def delete_user_feedback(%User.Feedback{} = user_feedback) do
    Repo.delete(user_feedback)
  end

  def delete_user_feedback!(%User.Feedback{} = user_feedback) do
    Repo.delete!(user_feedback)
  end

  def index_devices(user_id, params) do
    User.Device
    |> Ecto.Query.select([ud], ud)
    |> Ecto.Query.where([ud], ud.user_id == ^user_id)
    |> Ecto.Query.preload([:user])
    |> Repo.paginate(params)
  end

  def get_device(params) do
    Repo.get_by(User.Device, params)
  end

  def create_or_update_device(id, attrs) do
    get_device(id: id)
    |> case do
      %User.Device{} = device -> update_device(device, attrs)
      _ -> create_device(attrs)
    end
  end

  def create_device(attrs \\ %{}) do
    %User.Device{}
    |> User.Device.changeset(attrs)
    |> Repo.insert()
  end

  def update_device(%User.Device{} = device, attrs \\ %{}) do
    device
    |> User.Device.changeset(attrs)
    |> Repo.update()
  end

  def delete_device(%User.Device{} = device) do
    Repo.delete(device)
  end

  def create_business_account(owner_user, admin_username, categories, attrs) do
    with {:ok, admin_user} <- get_user(username: admin_username) do
      generated_password = :crypto.strong_rand_bytes(12) |> Base.url_encode64() |> binary_part(0, 12)

      attrs = Map.merge(attrs, %{
        is_business: true,
        password: generated_password
      })

      result =
        Ecto.Multi.new()
        |> Ecto.Multi.run(:insert_business_account, fn _, _ ->
          create(attrs)
        end)
        |> Ecto.Multi.run(:add_owner, fn _, %{insert_business_account: business_account} ->
          Memberships.add_member(business_account, owner_user, "owner")
        end)
        |> Ecto.Multi.run(:add_admin_user, fn _, %{insert_business_account: business_account} ->
          if owner_user.id != admin_user.id do
            Memberships.add_member(business_account, admin_user, "admin")
          else
            {:ok, nil}
          end
        end)
        |> Ecto.Multi.run(:add_categories, fn _, %{insert_business_account: business_account} ->
          BillBored.Businesses.add_categories_to_business(categories, business_account.id)
          {:ok, nil}
        end)
        |> Repo.transaction()

      with {:ok, %{insert_business_account: business_account}} <- result do
        {:ok, business_account |> Repo.preload(:business_category)}
      end
    end
  end

  def search_user_by_name_like_criteria(name_criteria, params \\ %{}) do
    from(u in User.available(params),
      where:
        like(
          fragment("lower(?)", u.username),
          ^String.downcase("%#{name_criteria}%")
        ) and u.is_business == false
    )
    |> Repo.all()
  end

  def search_by_username(name_criteria, params \\ %{}) do
    from(u in User.available(params),
      where:
        like(
          fragment("lower(?)", u.username),
          ^String.downcase("%#{name_criteria}%")
        ) and u.is_business == false
    )
    |> Repo.all()
  end

  def search_by_first_name(name_criteria, params \\ %{}) do
    from(u in User.available(params),
      where:
        like(
          fragment("lower(?)", u.first_name),
          ^String.downcase("%#{name_criteria}%")
        ) and u.is_business == false
    )
    |> Repo.all()
  end

  def search_by_last_name(name_criteria, params \\ %{}) do
    from(u in User.available(params),
      where:
        like(
          fragment("lower(?)", u.last_name),
          ^String.downcase("%#{name_criteria}%")
        ) and u.is_business == false
    )
    |> Repo.all()
  end

  def search_by_email(email, params \\ %{}) do
    from(u in User.available(params),
      where: u.email == ^email and u.is_business == false
    )
    |> Repo.all()
  end

  def search_by_country_code_and_phone(country_code, phone, params \\ %{}) do
    from(u in User.available(params),
      where: u.country_code == ^country_code and u.phone == ^phone and u.is_business == false
    )
    |> Repo.all()
  end

  def search_by_phone_numbers(phonenumbers, params \\ %{}) do
    from(u in User.available(params),
      where: u.phone in ^phonenumbers and u.is_business == false
    )
    |> Repo.all()
  end

  def search_by_phone(phone, params \\ %{}) do
    from(u in User.available(params),
      where: u.phone == ^phone and u.is_business == false
    )
    |> Repo.all()
  end

  def search_by_interest(interest, params \\ %{}) do
    interest = "#{interest}%"

    from(u in User.available(params),
      join: i in assoc(u, :interests_interest),
      where: like(i.hashtag, ^interest)
    )
    |> Repo.all()
  end

  def registration_status(%User{phone: phone, verified_phone: verified_phone}) do
    if !is_nil(phone) && phone == verified_phone do
      :complete
    else
      :phone_verification_required
    end
  end

  def login(username, password) do
    with {:ok, user} <- get_user(username: username),
         {:ok, result} <- sign_in_user(user, password) do
      {:ok, user, result}
    end
  end

  def login_by_email(email, password) do
    with {:ok, user} <- get_user(email: email),
         {:ok, result} <- sign_in_user(user, password) do
      {:ok, user, result}
    end
  end

  defp get_user(username: username) do
    case get_by_username(username) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, :user_not_found}
    end
  end

  defp get_user(email: email) do
    case get_by_email(email) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, :user_not_found}
    end
  end

  def get_business_account(id: id) do
    business_account =
      from(u in User, where: u.id == ^id and u.is_business == true)
      |> Repo.one()

    case business_account do
      %User{} -> {:ok, business_account}
      _ -> {:error, :business_account_not_found}
    end
  end

  defp sign_in_user(%User{password: actual_password} = user, attempted_password) do
    with true <- verify_pass(attempted_password, actual_password),
         {:ok, token} <- AuthTokens.sign_in(user),
         :ok <- maybe_follow_autofollowed_users(user) do
      {:ok, %{
        token: token,
        registration_status: registration_status(user)
      }}
    else
      _ ->
        {:error, :user_not_found}
    end
  end

  defp maybe_follow_autofollowed_users(%{flags: %{"autofollow" => _}} = _user), do: :ok
  defp maybe_follow_autofollowed_users(%{id: user_id}) do
    UserRecommendations.follow_autofollow_recommendations(user_id)
    :ok
  end

  def verify(
        %PhoneVerificationModel{} = phone_verification,
        %User{phone: phone, country_code: country_code} = user
      ) do
    if phone && country_code do
      service(PhoneVerification).check(%{
        phone_number: %PhoneVerification.PhoneNumber{
          country_code: country_code,
          subscriber_number: phone
        },
        # TODO why is otp being sent?
        verification_code: phone_verification.otp
      })
      |> case do
        {:ok, _response} = success ->
          user
          |> Ecto.Changeset.change(verified_phone: phone)
          |> Ecto.Changeset.unique_constraint(:phone, name: :accounts_userprofile_phone_8e09b259_uniq)
          |> Repo.update()
          |> case do
            {:ok, _} -> success
            {:error, %Ecto.Changeset{valid?: false, errors: errors}} ->
              case Keyword.get(errors, :phone) do
                {"has already been taken", _} -> {:error, :duplicate_phone_number}
                _ -> {:error, :internal_error}
              end
            _ -> {:error, :internal_error}
          end

        {:error, %{message: message}} ->
          {:error, message}
      end
    else
      {:error, "Phone Number and Country Code has not been provided yet!!!"}
    end
  end

  alias BillBored.Users.ChangePassword

  @doc """
  Gets a single change_password.

  Raises `Ecto.NoResultsError` if the Change password does not exist.

  ## Examples

      iex> get_change_password!(123)
      %ChangePassword{}

      iex> get_change_password!(456)
      ** (Ecto.NoResultsError)

  """
  def get_change_password!(id), do: Repo.get!(ChangePassword, id)

  @doc """
  Gets all change_password request by user.

  ## Examples

      iex> get_change_password_by_user(1)
      [...]

      iex> get_change_password_by_user(2)
      []

  """
  @spec get_change_password_by_user(pos_integer) :: list(ChangePassword.t()) | list()
  def get_change_password_by_user(user_id) do
    import Ecto.Query

    ChangePassword
    |> where([cp], cp.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
    Check a active hash.

    Raises `Ecto.NoResultsError` if the Change password does not exist.

  ## Examples

      iex> check_active_hash!("asdadasdad123asd")
      %ChangePassword{}

      iex> check_active_hash!("asdasd")
      ** (Ecto.NoResultsError)

  """
  @spec get_change_password_by_hash(String.t()) :: ChangePassword.t() | nil
  def get_change_password_by_hash(hash), do: Repo.get_by(ChangePassword, hash: hash)

  @doc """
    Creates a change_password.

  ## Examples

      iex> create_change_password(%{field: value})
      {:ok, %ChangePassword{}}

      iex> create_change_password(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_change_password(attrs \\ %{}) do
    %ChangePassword{}
    |> ChangePassword.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a ChangePassword.

  ## Examples

      iex> delete_change_password(change_password)
      {:ok, %ChangePassword{}}

      iex> delete_change_password(change_password)
      {:error, %Ecto.Changeset{}}

  """
  def delete_change_password(%ChangePassword{} = change_password) do
    Repo.delete(change_password)
  end

  def get_close_friends(user_id) do
    friends_ids = list_friend_ids(user_id)

    User.CloseFriendship
    |> where([cf], cf.from_userprofile_id == ^user_id)
    |> where([cf], cf.to_userprofile_id in ^friends_ids)
    |> Ecto.Query.preload(:to)
    |> Repo.all()
  end

  def get_close_friend_requests(user_id) do
    friends_ids = list_friend_ids(user_id)

    User.CloseFriendship
    |> where([cf], cf.from_userprofile_id == ^user_id)
    |> where([cf], cf.to_userprofile_id not in ^friends_ids)
    |> where([cf], cf.to_userprofile_id != ^user_id)
    |> distinct(true)
    |> Ecto.Query.preload(:to)
    |> Repo.all()
  end

  def create_close_friendship(user_id_from, user_id_to) do
    %User.CloseFriendship{}
    |> User.CloseFriendship.changeset(%{
      from_userprofile_id: user_id_from,
      to_userprofile_id: user_id_to
    })
    |> Repo.insert()
  end

  def delete_close_friendship(%User.CloseFriendship{} = close_friendship) do
    Repo.delete(close_friendship)
  end

  def get_user_interests(user_id) do
    User.Interest
    |> where([ui], ui.user_id == ^user_id)
    |> Repo.all()
  end

  def get_member_of_busisness_account(busisness_account_name) do
    busisness_account_name
    |> BillBored.Users.get_by_username()
    |> BillBored.User.Memberships.members_of()
  end

  def get_admin_of_busisness_account(busisness_account_name) do
    busisness_account_name
    |> BillBored.Users.get_by_username()
    |> BillBored.User.Memberships.admins_of()
  end

  # TODO rewrite
  def update_business_account(
        business_id,
        business_account_name,
        admin_user,
        avatar,
        avatar_thumbnail,
        categories_to_add
      ) do
    admin_user = BillBored.Users.get_by_username(admin_user)

    if admin_user == nil do
      %{"status" => 404, "message" => "No admin user found using the giving login!"}
    else
      found_business_account_by_name = BillBored.Users.get_by_first_name(business_account_name)

      if found_business_account_by_name == nil do
        BillBored.Users.get_by_id(business_id)
        |> Ecto.Changeset.change(%{
          first_name: business_account_name,
          admin_user: admin_user,
          avatar: avatar,
          avatar_thumbnail: avatar_thumbnail
        })
        |> Repo.insert_or_update()

        if categories_to_add != nil do
          BillBored.Businesses.add_categories_to_business(categories_to_add, business_id)
          updated_account = BillBored.Users.get_by_id(business_id)
          %{"status" => 201, "account" => updated_account}
        else
          updated_account = BillBored.Users.get_by_id(business_id)
          %{"status" => 201, "account" => updated_account}
        end
      else
        %{"status" => 409, "message" => "Name already in use!"}
      end
    end
  end

  def add_member_to_business_account(members_to_add) do
    Enum.each(members_to_add, fn member_to_add ->
      account = BillBored.Users.get_by_username(member_to_add["business_account_username"])
      member = BillBored.Users.get_by_username(member_to_add["username"])
      role = member_to_add["role"]
      BillBored.User.Memberships.add_member(account, member, role)
    end)
  end

  def change_member_role_on_business_account(business_account_username, username, role) do
    account = BillBored.Users.get_by_username(business_account_username)
    member = BillBored.Users.get_by_username(username)
    BillBored.User.Memberships.update_role(account, member, role)
  end

  def remove_member_from_business_account(business_account_username, username) do
    account = BillBored.Users.get_by_username(business_account_username)
    member = BillBored.Users.get_by_username(username)
    {records, nil} = BillBored.User.Memberships.remove_member(account, member)

    if records > 0 do
      {:ok, %{message: "User was delete from Business Account"}}
    else
      {:ok, %{message: "User doesn't exists on this Business Account"}}
    end
  end

  def close_business_user_account(username) do
    member = BillBored.Users.get_by_username(username)
    {records, nil} = BillBored.User.Memberships.delete_personal_owner_account(member)

    if records > 0 do
      {:ok, %{message: "Personal business account was closed!"}}
    else
      {:ok, %{message: "User doesn't exists."}}
    end
  end

  def close_business_account(business_account_name) do
    business_account = BillBored.Users.get_by_username(business_account_name)
    {records, nil} = BillBored.User.Memberships.delete_business_account(business_account)

    if records > 0 do
      {:ok, %{message: "Business Account was closed!"}}
    else
      {:ok, %{message: "Business Account doesn't exists!"}}
    end
  end

  def followed_users(%User{id: user_id}) do
    Following
    |> where([f], f.from_userprofile_id == ^user_id)
    |> select([f], f.to_userprofile_id)
    |> Repo.all()
  end

  # TODO optimize
  def follow_suggestions_query(%User{id: user_id} = user, followed_users) do
    import Geo.PostGIS, only: [st_distance_in_meters: 2]

    user_interests =
      user_id
      |> get_user_interests()
      |> Enum.map(& &1.interest_id)

    users_same_interest =
      User.Interest
      |> where([ui], ui.interest_id in ^user_interests)
      |> where([ui], ui.user_id != ^user_id)
      |> distinct(true)
      |> select([ui], ui.user_id)
      |> Repo.all()

    users_nearby =
      User
      |> where(
        [u],
        st_distance_in_meters(u.user_real_location, ^user.user_real_location) <
          fragment("? * 1000", ^user.prefered_radius)
      )
      |> select([u], u.id)
      |> Repo.all()

    User.available(%{for_id: user.id})
    |> where([u], is_nil(u.event_provider))
    |> where([u], u.id in ^users_same_interest or u.id in ^users_nearby)
    |> where([u], u.id != ^user_id)
    |> where([u], u.id not in ^followed_users)
    |> preload(:university)
  end

  def search_user_ids_by_interests([]), do: []

  def search_user_ids_by_interests(interests) do
    interest_ids =
      interests
      |> Enum.map(& &1.id)

    User.Interest
      |> where([ui], ui.interest_id in ^interest_ids)
      |> distinct(true)
      |> select([ui], ui.user_id)
      |> Repo.all()
  end

  def oldest_users(%User{} = user, followed_users) do
    User.available(%{for_id: user.id})
    |> order_by(asc: :id)
    |> where([u], is_nil(u.event_provider))
    |> where([u], u.id != ^user.id)
    |> where([u], u.id not in ^followed_users)
    |> limit(20)
    |> preload(:university)
    |> Repo.all()
  end

  def most_followed_users(%User{} = user, followed_users) do
    User.available(%{for_id: user.id})
    |> where([u], is_nil(u.event_provider))
    |> where([u], u.id != ^user.id)
    |> where([u], u.id not in ^followed_users)
    |> join(:left, [u], f in Following, on: f.to_userprofile_id == u.id)
    |> having([..., f], count(f.to_userprofile_id) > 0)
    |> order_by([..., f], desc: count(f.to_userprofile_id))
    |> group_by([u], u.id)
    |> limit(30)
    |> preload(:university)
    |> Repo.all()
  end

  def replace_flags(user_id, replace, remove \\ []) do
    Repo.transaction(fn _ ->
      user = Repo.get!(User, user_id)

      new_flags =
        user.flags
        |> Map.drop(remove)
        |> Map.merge(replace)

      Ecto.Changeset.change(user, %{flags: new_flags})
      |> Repo.update!()
    end)
  end

  def update_flags(user_id, flags, update_fun) do
    Repo.transaction(fn _ ->
      user = Repo.get!(User, user_id)

      updated_flags = Enum.reduce(flags, %{}, fn flag, acc ->
        Map.put(acc, flag, update_fun.(flag, user.flags[flag]))
      end)

      Ecto.Changeset.change(user, %{flags: Map.merge(user.flags, updated_flags)})
      |> Repo.update!()
    end)
  end

  @streaming_time_bucket 86400
  @streaming_time_per_bucket 10800

  def get_available_streaming_time(%User{flags: flags}) do
    now_ts = DateTime.utc_now() |> DateTime.to_unix()
    now_bucket = now_ts - rem(now_ts, @streaming_time_bucket)
    if !flags["streaming_time_bucket"] || flags["streaming_time_bucket"] < now_bucket do
      @streaming_time_per_bucket
    else
      flags["streaming_time_remaining"]
    end
  end

  def subtract_available_streaming_time(%User{flags: flags} = user, seconds) do
    now_ts = DateTime.utc_now() |> DateTime.to_unix()
    now_bucket = now_ts - rem(now_ts, @streaming_time_bucket)

    if !flags["streaming_time_bucket"] || flags["streaming_time_bucket"] < now_bucket do
      replace_flags(user.id, %{
        "streaming_time_remaining" => @streaming_time_per_bucket,
        "streaming_time_bucket" => now_bucket
      })
    else
      update_flags(user.id, ["streaming_time_remaining"], fn
        "streaming_time_remaining", old_time ->
          old_time - seconds
      end)
    end
  end

  def update_online_statuses(users_last_online_at) do
    json_updates =
      Enum.map(users_last_online_at, fn {user_id, last_online_at} ->
        %{
          id: user_id,
          last_online_at: last_online_at
        }
      end)
      |> Jason.encode!()

    Repo.update_all(
      from(u in User,
        join:
          j in fragment(
            "SELECT * FROM jsonb_to_recordset(?::jsonb) v (id integer, last_online_at timestamptz)",
            type(^json_updates, :string)
          ),
          on: u.id == j.id,
        update: [set: [last_online_at: j.last_online_at]]
      ),
      []
    )
  end
end
