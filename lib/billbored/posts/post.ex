defmodule BillBored.Post do
  use BillBored, :schema
  use BillBored.User.Blockable, foreign_key: :author_id
  alias BillBored.{Admin, User, Users, Place, Poll, Interest, Post, PostReport, Event, Upload, BusinessOffer}

  import BillBored.Geo, only: [fake_place: 1]
  import BillBored.Helpers, only: [media_files_from_keys: 1]
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @review_status_values ~w(pending rejected accepted)s
  @valid_event_providers ~w(eventful meetup allevents)s

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:location, BillBored.Geo.Point)
    field(:location_geohash, :integer)
    field(:fake_location, BillBored.Geo.Point)
    field(:post_cost, :integer)
    field(:private?, :boolean, default: false)
    field(:type, :string)
    field(:approved?, :boolean, default: true)
    field(:popular_notified?, :boolean)
    field(:hidden?, :boolean, default: false)
    field(:review_status, :string, default: nil)
    field(:last_reviewed_at, :utc_datetime_usec, default: nil)

    field(:business_name, :string)

    field(:downvotes_count, :integer, default: 0, virtual: true)
    field(:upvotes_count, :integer, default: 0, virtual: true)
    field(:comments_count, :integer, default: 0, virtual: true)
    field(:reports_count, :integer, default: 0, virtual: true)
    field(:posts_count, :integer, default: 0, virtual: true)

    field(:user_upvoted?, :boolean, default: false, virtual: true)
    field(:user_downvoted?, :boolean, default: false, virtual: true)

    field(:eventbrite_id, :integer)
    field(:eventful_id, :string)

    field(:event_provider, :string)
    field(:provider_id, :string)

    belongs_to(:author, User)
    belongs_to(:admin_author, Admin)
    belongs_to(:place, Place)
    belongs_to(:business, User)
    belongs_to(:business_admin, User)

    has_many(:polls, Poll, on_replace: :delete)
    has_many(:comments, Post.Comment)
    has_many(:events, Event, on_replace: :delete, on_delete: :delete_all)
    has_many(:reports, PostReport)

    has_one(:business_offer, BusinessOffer, on_replace: :delete)

    many_to_many(:interests, Interest, join_through: Post.Interest, on_replace: :delete)

    many_to_many :media_files, Upload,
      join_through: "post_uploads",
      join_keys: [post_id: :id, upload_key: :media_key],
      on_replace: :delete

    field :eventbrite_urls, {:array, :string}
    field :eventful_urls, {:array, :string}
    field :provider_urls, {:array, :string}

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)
  end

  def available(params) do
    if params[:for_id] || params[:for] do
      from(p in Post.not_blocked(params),
        left_join: a in assoc(p, :author),
        where: p.hidden? == false and (is_nil(p.author_id) or (a.banned? == false and a.deleted? == false))
      )
    else
      from(p in Post,
        left_join: a in assoc(p, :author),
        where: p.hidden? == false and (is_nil(p.author_id) or (a.banned? == false and a.deleted? == false))
      )
    end
  end

  defp trim_title(%{"title" => title} = attrs) when not is_nil(title) do
    %{attrs | "title" => String.trim(title)}
  end

  defp trim_title(attrs), do: attrs

  # TODO this is a workaround, to be replaced with a proper business entity
  defp prepare_business(attrs) do
    if business_name = attrs["business_username"] do
      if business = Users.get_by_username(business_name) do
        Map.put(attrs, "business_id", business.id)
      end
    end || attrs
  end

  def changeset(post, attrs) do
    attrs =
      attrs
      |> trim_title()
      # TODO remove once we have proper business entity
      |> prepare_business()

    post
    |> cast(attrs, [
      :title,
      :body,
      :location,
      :private?,
      :type,
      :post_cost,
      # TODO don't cast foreign keys -> leads to vulnerability
      :place_id,
      :author_id,
      :admin_author_id,
      :business_id,
      :business_admin_id,
      :business_name,
      :event_provider,
      :provider_id
    ])
    |> put_assoc(:media_files, media_files_from_keys(attrs["media_file_keys"] || []))
    |> cast_assoc(:polls, with: &Poll.changeset/2)
    |> cast_assoc(:events, with: &Event.changeset/2)
    |> add_fake_location(attrs["fake?"] || attrs["fake"])
    |> maybe_update_location_geohash()
    |> maybe_reset_review_status()
    |> validate_required([:type, :location])
    |> validate_type()
    |> validate_number(:post_cost, greater_than_or_equal_to: 0)
    |> validate_length(:title, min: 5, max: 200)
    |> validate_business()
    |> cast_business_offer()
    |> validate_inclusion(:review_status, @review_status_values)
    |> validate_inclusion(:event_provider, @valid_event_providers)
    |> check_constraint(:author_id, name: :validate_author_id, message: "or admin_author_id must exist, but not both.")
    |> check_constraint(:admin_author_id, name: :validate_author_id, message: "or author_id must exist, but not both.")
    |> foreign_key_constraint(:business_id)
    |> foreign_key_constraint(:author_id)
    |> foreign_key_constraint(:admin_author_id)
    |> foreign_key_constraint(:place_id)
    |> unique_constraint(:id, name: :posts_pkey, message: "can't be duplicated")
  end

  def cast_business_offer(changeset) do
    case get_field(changeset, :type) do
      "offer" ->
        case changeset.params do
          %{"business_offer" => business_offer_params} ->
            business_offer_attrs = Map.put(business_offer_params, "business_id", get_field(changeset, :business_id))
            business_offer_changeset = BusinessOffer.changeset(%BusinessOffer{}, business_offer_attrs)
            put_assoc(changeset, :business_offer, business_offer_changeset)

          _ ->
            changeset
        end

      _ ->
        changeset
    end
  end

  def admin_changeset(post, attrs) do
    post
    |> cast(attrs, [:hidden?, :review_status, :last_reviewed_at])
  end

  defp validate_type(changeset) do
    case get_field(changeset, :type) do
      "poll" ->
        if get_field(changeset, :polls) == [] do
          add_error(
            changeset,
            :polls,
            "should include at least one poll for the post type `poll`"
          )
        else
          changeset
        end

      "post" ->
        if get_field(changeset, :events) == [] do
          add_error(
            changeset,
            :events,
            "should include at least one event for the post type `event`"
          )
        else
          changeset
        end

      _ ->
        validate_inclusion(changeset, :type, ["vote", "poll", "regular", "event", "offer"])
    end
  end

  defp validate_business(cs = _changeset) do
    business_id = get_field(cs, :business_id)
    business_name = get_field(cs, :business_name)
    business_admin_id = get_field(cs, :business_admin_id)

    post_cost = get_field(cs, :post_cost)

    if business_id do
      business = Users.get(business_id)

      if business do
        cs = put_change(cs, :author_id, business.id)

        cs =
          unless business_name do
            put_change(cs, :business_name, business.username)
          end || cs

        cs =
          unless business_admin_id do
            put_change(cs, :business_admin_id, business.id)
          end || cs

        unless business.is_business do
          msg = "account with id #{business_id} is not business"
          add_error(cs, :business_id, msg)
        end || cs
      else
        msg = "business account with id #{business_id} does not exist"
        add_error(cs, :business_id, msg)
      end
    else
      cs =
        if business_name do
          msg = "business name #{business_name} is given, but `business_id` is missing"
          add_error(cs, :business_name, msg)
        end || cs

      cs =
        if business_admin_id do
          msg = "business admin is given, but `business_id` is missing"
          add_error(cs, :business_admin_id, msg)
        end || cs

      if post_cost && post_cost > 0 do
        msg = "`post_cost` can be given only for business posts"
        add_error(cs, :post_cost, msg)
      end || cs
    end
    |> validate_length(:business_name, max: 80)
  end

  # TODO test
  defp add_fake_location(changeset, make_fake?) do
    if make_fake? do
      %BillBored.Geo.Point{lat: lat, long: long} = get_field(changeset, :location)

      case fake_place({lat, long}) do
        {:ok, fake_place} ->
          changeset
          |> put_change(:fake_location, fake_place.location)
          |> put_change(:place_id, fake_place.id)

        :error ->
          add_error(changeset, :fake_location, "Fake location cannot be generated!")
      end
    else
      changeset
    end
  end

  defp maybe_update_location_geohash(changeset) do
    with nil <- get_change(changeset, :fake_location),
         nil <- get_change(changeset, :location) do
      changeset
    else
      %BillBored.Geo.Point{long: lon, lat: lat} ->
        put_change(
          changeset,
          :location_geohash,
          BillBored.Geo.Hash.to_integer(Geohash.encode(lat, lon, 12))
        )
    end
  end

  defp maybe_reset_review_status(changeset) do
    title_changed = !!get_change(changeset, :title)
    body_changed = !!get_change(changeset, :body)
    media_changed = get_change(changeset, :media_files, []) |> Enum.any?()

    if title_changed || body_changed || media_changed do
      changeset
      |> put_change(:review_status, nil)
    else
      changeset
    end
  end
end
