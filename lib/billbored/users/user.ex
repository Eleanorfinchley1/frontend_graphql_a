defmodule BillBored.User do
  use BillBored, :schema
  use BillBored.User.Blockable, foreign_key: :id

  import Ecto.Query
  import Ecto.Changeset
  import Bcrypt, only: [hash_pwd_salt: 1]

  alias BillBored.{User, University, UserPoint, Interest, User.Membership, BusinessCategory, BusinessesCategories}
  alias BillBored.Notifications.AreaNotification
  alias BillBored.Notifications.AreaNotificationReception

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
           only: [
             :username,
             :avatar,
             :avatar_thumbnail,
             :first_name,
             :last_name,
             :interests_interest
           ]}
  schema "accounts_userprofile" do
    field(:password, :string)
    field(:is_superuser, :boolean, default: false)
    field(:username, :string)
    field(:first_name, :string, default: "")
    field(:last_name, :string, default: "")
    field(:email, :string, default: "")
    # field(:university_id, :integer)
    field(:is_staff, :boolean, default: false)
    field(:is_active, :boolean, default: true)
    # TODO this won't work, since default is executed at build time
    field(:date_joined, :utc_datetime_usec, default: DateTime.utc_now())
    field(:avatar, :string, default: "")
    field(:bio, :string, default: "")
    field(:sex, :string, default: "")
    field(:birthdate, :date)
    field(:prefered_radius, :integer, default: 10)
    field(:enable_push_notifications, :boolean, default: true)
    field(:avatar_thumbnail, :string, default: "")
    field(:country_code, :string, default: "")
    field(:phone, :string)
    field(:verified_email, :string, default: "false")
    field(:verified_phone, :string)
    field(:user_real_location, BillBored.Geo.Point)
    field(:user_safe_location, BillBored.Geo.Point)
    field(:area, :string, default: "")
    field(:is_business, :boolean, default: false)
    field(:eventbrite_id, :integer)
    field(:eventful_id, :string)
    field(:banned?, :boolean, default: false)
    field(:deleted?, :boolean, default: false)

    field(:event_provider, :string)
    field(:provider_id, :string)

    field(:flags, :map, default: %{})

    field(:last_online_at, :utc_datetime_usec)

    # virtual fields
    field(:token, :string, virtual: true)

    field(:blocks_count, :integer, default: 0, virtual: true)
    field(:blocked_from_id, :integer, default: nil, virtual: true)
    field(:blocked_to_id, :integer, default: nil, virtual: true)
    field(:location_reward_notification_id, :integer, default: nil, virtual: true)

    field(:role, :string, virtual: true)
    field(:privileges, {:array, :string}, virtual: true)

    field(:referral_code, :string)

    field(:followers_count, :integer, virtual: true)

    field(:is_follower, :boolean, virtual: true)
    field(:is_following, :boolean, virtual: true)
    field(:is_ghost, :boolean, virtual: true)

    field(:streams_count, :integer, virtual: true)
    field(:claps_count, :integer, virtual: true)
    field(:semester_points, :integer, virtual: true)
    field(:monthly_points, :integer, virtual: true)
    field(:weekly_points, :integer, virtual: true)
    field(:daily_points, :integer, virtual: true)
    field(:total_points, :integer, virtual: true)

    has_many(:devices, __MODULE__.Device)

    has_many(:recommendations, User.Recommendation)

    many_to_many(:interests_interest, Interest, join_through: User.Interest, where: [disabled?: false])

    many_to_many(
      :business_accounts,
      User,
      join_through: Membership,
      join_keys: [member_id: :id, business_account_id: :id]
    )

    many_to_many(
      :members,
      User,
      join_through: Membership,
      join_keys: [business_account_id: :id, member_id: :id]
    )

    many_to_many(
      :business_category,
      BusinessCategory,
      join_through: BusinessesCategories,
      join_keys: [user_id: :id, business_category_id: :id]
    )

    has_many(:businesses_categories, BusinessesCategories)

    many_to_many(:received_area_notifications, AreaNotification, join_through: AreaNotificationReception)

    has_one(:business_suggestion, BillBored.BusinessSuggestion, foreign_key: :business_id)
    has_one(:points, UserPoint, foreign_key: :user_id)
    has_one :mentor,
      BillBored.Users.Mentor,
      foreign_key: :mentor_id

    has_one :mentee,
      BillBored.Users.Mentee,
      foreign_key: :user_id

    many_to_many(
      :mentees,
      User,
      join_through: BillBored.Users.Mentee,
      join_keys: [mentor_id: :id, user_id: :id]
    )

    has_one :mentee_mentor, through: [:mentee, :mentor, :user]

    belongs_to(:university, University, foreign_key: :university_id)
  end

  def available(params) do
    from(p in BillBored.User.not_blocked(params),
      where: p.banned? == false and p.deleted? == false
    )
  end

  @required_fields ~w(username password email)a
  @optional_fields ~w(first_name last_name is_staff is_active is_superuser
                      date_joined avatar bio birthdate prefered_radius
                      enable_push_notifications avatar_thumbnail country_code phone area is_business sex
                      event_provider provider_id user_real_location referral_code flags last_online_at university_id)a

  @valid_event_providers ~w(eventful meetup allevents)s

  @doc false
  def create_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required_username()
    |> validate_required(@required_fields)
    |> validate_inclusion(:event_provider, @valid_event_providers)
    |> foreign_key_constraint(:university_id)
    |> unique_constraint(:nickname, name: :accounts_userprofile_username_key)
    |> encrypt_password()
    |> default_values()
  end

  def update_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_inclusion(:event_provider, @valid_event_providers)
    |> unique_constraint(:nickname, name: :accounts_userprofile_username_key)
    |> unique_constraint(:phone, name: :accounts_userprofile_phone_8e09b259_uniq)
    |> encrypt_password()
  end

  def admin_changeset(post, attrs) do
    post
    |> cast(attrs, [:banned?, :deleted?, :flags])
  end

  defp validate_required_username(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, data: %{username: _username}} ->
        changeset

      _ ->
        put_change(changeset, :username, get_random_username())
    end
  end

  defp get_random_username(size \\ 10) do
    alphabets = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    numbers = "0123456789"

    list =
      [alphabets, String.downcase(alphabets), numbers]
      |> IO.iodata_to_binary()
      |> String.split("", trim: true)

    1..size
    |> Enum.reduce([], fn _, acc -> [Enum.random(list) | acc] end)
    |> Enum.join("")
  end

  defp default_values(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        changeset
        |> check_for_change_default(:referral_code, UUID.uuid4())
        |> check_for_change_default(:is_superuser, false)
        |> check_for_change_default(:is_business, false)
        |> check_for_change_default(:is_staff, false)
        |> check_for_change_default(:is_active, true)
        |> check_for_change_default(:date_joined, DateTime.utc_now())
        |> check_for_change_default(:first_name, "")
        |> check_for_change_default(:last_name, "")
        |> check_for_change_default(:email, "")
        |> check_for_change_default(:avatar, "")
        |> check_for_change_default(:avatar_thumbnail, "")
        |> check_for_change_default(:bio, "")
        |> check_for_change_default(:sex, "")
        |> check_for_change_default(:prefered_radius, 5)
        |> check_for_change_default(:country_code, "")
        |> check_for_change_default(:enable_push_notifications, true)
        |> check_for_change_default(:area, "")

      _ ->
        changeset
    end
  end

  defp check_for_change_default(changeset, field, default) do
    if get_change(changeset, field) == nil do
      put_change(changeset, field, default)
    else
      changeset
    end
  end

  # encrypt password using BCrypt
  defp encrypt_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password, hash_pwd_salt(pass))

      _ ->
        changeset
    end
  end

  def validate_phone(changeset) do
    case get_change(changeset, :phone) do
      nil ->
        changeset

      phone ->
        country_code = get_field(changeset, :country_code)

        query = from(u in BillBored.User,
          where: u.country_code == ^country_code and u.verified_phone == ^phone)

        if Repo.exists?(query) do
          add_error(changeset, :phone, "has already been taken")
        else
          changeset
        end
    end
  end
end
