defmodule BillBored.Uploads do
  import Ecto.Query

  alias BillBored.Upload

  def get_by_media_key(media_key) do
    from(u in Upload, where: u.media_key == ^media_key)
    |> Repo.one()
  end
end
