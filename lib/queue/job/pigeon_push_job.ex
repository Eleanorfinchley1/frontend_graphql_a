defmodule Queue.PigeonPushJob do
  @behaviour Rihanna.Job
  require Logger

  @impl true
  def perform(notifications) when is_list(notifications) do
    notifications = Enum.group_by(notifications, fn
      %Pigeon.APNS.Notification{} -> :ios
      %Pigeon.FCM.Notification{} -> :android
      _ -> :invalid
    end)

    ios_result = push_apns(notifications[:ios])
    push_android(notifications[:android])

    ios_result
  end

  defp push_apns(nil), do: :ok
  defp push_apns([]), do: :ok
  defp push_apns(notifications) do
    notifications
    |> Pigeon.APNS.push()
    |> filter_failed_apns()
    |> case do
      [] ->
        :ok

      failed_notifications ->
        Logger.error("Failed to push APNs notifications:\n#{inspect(failed_notifications)}")
        :error
    end
  end

  defp filter_failed_apns(notifications) do
    notifications
    # TODO https://github.com/codedge-llc/pigeon/blob/befddba5406769ae0ed169f4144a42769de5b473/lib/pigeon/apns.ex#L91
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(fn %Pigeon.APNS.Notification{response: response} ->
      response == :success
    end)
  end

  defp push_android(nil), do: :ok
  defp push_android([]), do: :ok
  defp push_android(notifications) do
    results = Pigeon.FCM.push(notifications)
    Logger.debug("Pushed FCM notifications: #{inspect(results, pretty: true)}")
    :ok
  end
end
