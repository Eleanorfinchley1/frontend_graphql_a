defmodule BillBored.Workers.GiveBonusDonationPoints do
  @moduledoc """
    If the user who receives the donation points uses them fully, both sender and receiver
    get more general point. Exemple, Joe request points, Joe's mentor, and list of friend
    will get a notification that Joe needs points. If Alicia gives 20 points to joe,
    alicia loses (20* 0.75). If Joe uses the points fully within 2h,
    then Alicia gets back ( 20 * 0.5) and Joe gets (20 * 0.75)
  """
  import Ecto.Query

  require Logger

  alias BillBored.{
    UserPoint,
    UserPoints,
    UserPointRequest,
    UserPointRequest.Donation,
    Chat.Room.DropchatStream
  }

  @bonus_alloc_minutes 120
  @points_per_minute Application.get_env(:billbored, UserPoints)[:points_per_minute]

  def call(now \\ DateTime.utc_now()) do
    created_after = %{DateTime.add(now, - trunc(@bonus_alloc_minutes * 60)) | second: 0}
    created_before = %{DateTime.add(now, - trunc(@bonus_alloc_minutes * 60 - 60)) | second: 0}
    point_requests =
      from(pr in UserPointRequest,
        join: ds in DropchatStream,
        on: pr.user_id == ds.admin_id and ds.status == "finished",
        where: pr.inserted_at >= ^created_after,
        where: pr.inserted_at < ^created_before,
        where: ds.finished_at > ^created_after,
        where: ds.finished_at < ^now,
        group_by: [pr.id, pr.user_id],
        select: %{
          id: pr.id,
          user_id: pr.user_id,
          minutes: fragment("coalesce(CAST(SUM(CEIL(EXTRACT(EPOCH FROM AGE(?, GREATEST(?, ?))) / 60)) AS INTEGER), 0)", ds.finished_at, ^created_after, ds.inserted_at)
        }
      )
      |> Repo.all()

    Enum.each(point_requests, fn point_request ->
      consumed_points = @points_per_minute * point_request.minutes

      donations = Donation
      |> where([d], d.request_id == ^point_request.id)
      |> order_by([d], asc: d.id)
      |> Repo.all()

      donations
      |> Enum.reduce(consumed_points, fn donation, consumed_points ->
        if donation.stream_points <= consumed_points do
          {3, [receiver_audit | sender_audits]} = Repo.insert_all(UserPoint.Audit, [
            %{
              user_id: donation.receiver_id,
              points: round(donation.stream_points * 0.75),
              p_type: "general",
              reason: "receiver_bonus",
              created_at: now,
            },
            %{
              user_id: donation.sender_id,
              points: round(donation.stream_points * 0.5),
              p_type: "general",
              reason: "sender_bonus",
              created_at: now,
            },
            %{
              user_id: donation.sender_id,
              points: donation.stream_points,
              p_type: "stream",
              reason: "recover",
              created_at: now,
            }
          ], returning: [:id, :user_id, :points, :p_type, :reason, :created_at])
          Notifications.process_consumed_donation(donation: donation, receiver_audit: receiver_audit, sender_audits: sender_audits)
          consumed_points - donation.stream_points
        else
          consumed_points
        end
      end)
    end)
  end
end
