defmodule BillBored.UserPoint.Audit do
  @moduledoc "schema for user_point_audits table"
  require Logger

  use BillBored, :schema

  @type t :: %__MODULE__{}

  schema "user_point_audits" do
    field(:user_id, :integer)
    field(:points, :integer)
    field(:p_type, :string)
    field(:reason, :string)
    field(:created_at, :utc_datetime_usec)
  end

  @castable [:user_id, :points, :p_type, :reason, :created_at]
  @required [:user_id, :points, :p_type, :reason]
  @valid_types ~w(stream general)s

  @valid_reasons ~w(signup signup_expire referral)s ++ # related signup
    ~w(anticipation anticipation_double)s ++ # related anticipation
    ~w(donate request recover sender_bonus receiver_bonus)s ++ # related requesting points
    ~w(daily)s ++
    ~w(location)s ++
    ~w(peak)s ++
    ~w(streaming)s ++
    ~w(absent)s

  @spec changeset(t, BillBored.attrs()) :: Ecto.Changeset.t()
  def changeset(audit, attrs) do
    audit
    |> cast(attrs, @castable)
    |> validate_required(@required)
    |> validate_inclusion(:p_type, @valid_types)
    |> validate_inclusion(:reason, @valid_reasons)
    |> validate_length(:p_type, max: 50)
    |> validate_length(:reason, max: 50)
    |> validate_points_based_on_type(attrs)
    |> check_constraint(:stream_points, name: :stream_points_must_be_greater_than_0, message: "stream_points can't be less than 0")
    |> check_constraint(:general_points, name: :general_points_must_be_greater_than_0, message: "general_points can't be less than 0")
  end

  defp validate_points_based_on_type(changeset, params) do
    p_type = params["p_type"]
    points = get_field(changeset, :points)

    validate_change(changeset, :points, fn _, _ ->
      if p_type == "general" and points < 0 do
         [points: "General point can't be negotive number"]
      else
        []
      end
    end)
  end
end
