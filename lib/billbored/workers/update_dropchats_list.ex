defmodule BillBored.Workers.UpdateDropchatsList do
  require Logger

  def call() do
    locations = Signer.Config.get(:user_locations) || %{}
    Web.Endpoint.broadcast(
      "dropchats",
      "dropchats:send_sorted_list",
      locations
    )
    Logger.debug("Send updated dropchats list to #{length(Map.keys(locations))} users.")
  end
end
