defmodule BillBored.Workers.GiveAbsentPoints do
  require Logger

  alias BillBored.{UserPoints}

  def call(_now \\ DateTime.utc_now()) do
    {num_rows, audits} = UserPoints.reduce_during_absent()
    Logger.info("Gave #{num_rows} absent points")
    Enum.each(audits, fn audit -> Notifications.process_user_point_audit(audit) end)
  end
end
