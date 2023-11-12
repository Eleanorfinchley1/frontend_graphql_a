defmodule BillBored.Workers.GiveDailyPoints do
  require Logger

  alias BillBored.{UserPoints}

  def call() do
    IO.inspect("Start giving daily points ....")
    {num_rows, audits} = UserPoints.give_daily_points()
    Logger.info("Give daily points with #{num_rows} records")
    Enum.each(audits, fn audit -> Notifications.process_user_point_audit(audit) end)
    IO.inspect("Finish giving daily points ....")
  end
end
