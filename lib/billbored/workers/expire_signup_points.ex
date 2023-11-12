defmodule BillBored.Workers.ExpireSignupPoints do
  require Logger

  alias BillBored.{UserPoints}

  def call() do
    {num_rows, audits} = UserPoints.expire_signup_points()
    Logger.info("Expired #{num_rows} signup points")
    Enum.each(audits, fn audit -> Notifications.process_user_point_audit(audit) end)
  end
end
