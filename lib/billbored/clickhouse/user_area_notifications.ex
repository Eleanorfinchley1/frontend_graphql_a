defmodule BillBored.Clickhouse.UserAreaNotifications do
  alias BillBored.Clickhouse.UserAreaNotification

  def create(%UserAreaNotification{} = user_area_notification) do
    Pillar.insert(
      BillBored.Clickhouse.conn(),
      """
        INSERT INTO user_area_notifications (
          user_id, timestamp, sent_at
        ) VALUES (
          {user_id}, {timestamp}, {sent_at}
        )
      """,
      Map.from_struct(user_area_notification)
    )
  end
end