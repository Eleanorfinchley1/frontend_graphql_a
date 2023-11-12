defmodule Repo.Migrations.AddConstraintsInUserPoints do
  use Ecto.Migration

  def change do
    create constraint(:user_points, :stream_points_must_be_greater_than_0, check: "stream_points >= 0")
    create constraint(:user_points, :general_points_must_be_greater_than_0, check: "general_points >= 0")
  end
end
