defmodule Repo.Migrations.AddEventfulUrls do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :eventful_urls, {:array, :string}
    end

    alter table(:events) do
      add :eventful_urls, {:array, :string}
    end
  end
end
