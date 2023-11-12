defmodule BillBored.Stubs.CachedPosts do
  def list_markers(search_location, filter \\ %{}), do: BillBored.Posts.list_markers(search_location, filter)
  def invalidate_post(_), do: {:ok, %{deleted_keys: 0}}
end
