defmodule BillBored.Clickhouse.UserAreaNotification do
  alias BillBored.User

  defstruct [
    :user_id, :timestamp, :sent_at
  ]

  def build(%User{id: user_id}, timestamp, attrs \\ %{}) do
    {:ok,
      %__MODULE__{
        user_id: user_id,
        timestamp: timestamp,
        sent_at: attrs["visited_at"] || attrs[:visited_at] || DateTime.utc_now()
    }}
  end
end
