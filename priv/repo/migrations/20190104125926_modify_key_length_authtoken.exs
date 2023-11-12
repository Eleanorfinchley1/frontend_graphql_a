defmodule Repo.Migrations.ModifyKeyLengthAuthtoken do
  use Ecto.Migration

  def change do
    alter table(:authtoken_token) do
      modify(:key, :varchar, null: false)
    end
  end
end
