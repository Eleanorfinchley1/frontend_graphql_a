defmodule Repo.Migrations.AddEventbriteUrls do
  use Ecto.Migration
  import Ecto.Query

  def up do
    alter table(:posts) do
      add :eventbrite_urls, {:array, :string}
    end

    alter table(:events) do
      add :eventbrite_urls, {:array, :string}
    end

    flush()

    "posts"
    |> where([p], not is_nil(p.eventbrite_id))
    |> update([p],
      set: [eventbrite_urls: p.media_file_keys, media_file_keys: fragment("ARRAY[]::VARCHAR[]")]
    )
    |> Repo.update_all([])

    "events"
    |> where([e], not is_nil(e.eventbrite_id))
    |> update([e],
      set: [eventbrite_urls: e.media_file_keys, media_file_keys: fragment("ARRAY[]::VARCHAR[]")]
    )
    |> Repo.update_all([])
  end

  def down do
    "posts"
    |> where([p], not is_nil(p.eventbrite_id))
    |> update([p], set: [eventbrite_urls: [], media_file_keys: p.eventbrite_urls])
    |> Repo.update_all([])

    "events"
    |> where([e], not is_nil(e.eventbrite_id))
    |> update([e], set: [eventbrite_urls: [], media_file_keys: e.eventbrite_urls])
    |> Repo.update_all([])

    alter table(:posts) do
      remove :eventbrite_urls, {:array, :string}
    end

    alter table(:events) do
      remove :eventbrite_urls, {:array, :string}
    end
  end
end
