defmodule BillBored.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Repo

  alias BillBored.{
    Event,
    User,
    Upload,
    Chat,
    Place,
    Interest,
    InterestCategory,
    InterestCategoryInterest,
    Hashtag,
    Livestream,
    Notification,
    Post,
    PostReportReason,
    PostReport,
    Poll,
    PollItem,
    EventSynchronization,
    Notifications.NotificationAreaNotification
  }

  # TODO fix with a proper struct
  def insert_user_friendship(attrs) do
    # user1 follows user2 and
    # user2 follows user1
    # means they are friends ...

    [user1, user2] = attrs[:users] || raise(ArgumentError, message: ":users are required")

    insert(:user_following, from: user1, to: user2)
    insert(:user_following, from: user2, to: user1)
  end

  # def insert_chat_message_with_membership(attrs) do

  # end

  def chat_message_factory do
    # TODO
    # unless Chat.Room.Memberships.get_by(user_id: user.id, room_id: room.id) do
    #   insert(:chat_room_membership, room: room, user: user)
    # end

    %Chat.Message{
      message: Faker.Lorem.sentence(3),
      is_seen: false,
      message_type: "TXT",
      user: build(:user),
      room: build(:chat_room)
    }
  end

  defp utc_now do
    DateTime.utc_now()
  end

  def upload_factory do
    %Upload{owner: build(:user), media_key: Ecto.UUID.generate()}
  end

  def user_factory(attrs) do
    image_url = Faker.Avatar.image_url()

    phone = if Map.has_key?(attrs, :phone) do
      attrs[:phone]
    else
      Faker.Phone.EnUs.phone()
    end

    verified_phone = if Map.has_key?(attrs, :verified_phone) do
      attrs[:verified_phone]
    else
      phone
    end

    user =
      %User{
        password: Faker.String.base64(10),
        is_superuser: false,
        username: Faker.Internet.user_name() <> "-#{:rand.uniform(99)}",
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: Faker.Internet.email(),
        is_staff: false,
        is_active: true,
        date_joined: utc_now(),
        avatar: image_url,
        bio: Faker.Lorem.sentence(10),
        sex: "M",
        birthdate: Faker.Date.date_of_birth(),
        prefered_radius: 1,
        enable_push_notifications: false,
        avatar_thumbnail: image_url,
        country_code: "+1",
        phone: phone,
        verified_phone: verified_phone,
        area: Faker.Address.city(),
        is_business: false,
        flags: %{"access" => "granted"}
      }

    Map.merge(user, attrs)
  end

  def user_device_factory do
    %User.Device{
      token: Faker.String.base64(10),
      platform: "ios",
      user: build(:user)
    }
  end

  def close_user_friendship_factory do
    %User.CloseFriendship{from: build(:user), to: build(:user)}
  end

  def user_following_factory do
    %User.Followings.Following{from: build(:user), to: build(:user)}
  end

  def user_membership_factory do
    %User.Membership{
      role: "member",
      business_account: build(:user, is_business: true),
      member: build(:user),
      required_approval: true
    }
  end

  def user_block_factory do
    %User.Block{
      blocker: build(:user),
      blocked: build(:user)
    }
  end

  def business_account_factory do
    image_url = Faker.Avatar.image_url()

    %User{
      password: Faker.String.base64(10),
      is_superuser: false,
      username: "business-" <> Faker.Internet.user_name() <> "-#{:rand.uniform(99)}",
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      email: Faker.Internet.email(),
      is_staff: false,
      is_active: true,
      is_business: true,
      date_joined: utc_now(),
      avatar: image_url,
      bio: Faker.Lorem.sentence(10),
      sex: "M",
      birthdate: Faker.Date.date_of_birth(),
      prefered_radius: 1,
      enable_push_notifications: false,
      avatar_thumbnail: image_url,
      country_code: "+1",
      area: Faker.Address.city(),
      user_real_location: %BillBored.Geo.Point{long: 30.0, lat: 40.0}
    }
  end

  def business_category_factory do
    %BillBored.BusinessCategory{
      category_name: Faker.Lorem.word()
    }
  end

  def businesses_categories_factory do
    %BillBored.BusinessesCategories{
      user: build(:business_account),
      business_category: build(:business_category)
    }
  end

  def business_offer_factory do
    %BillBored.BusinessOffer{
      business: build(:business_account),
      post: build(:post, type: "offer", title: Faker.Lorem.word(), body: Faker.Lorem.sentence()),
      expires_at: Timex.shift(Timex.now(), hours: 24)
    }
  end

  def business_post_factory(attrs) do
    {business_account, attrs} =
      case Access.pop(attrs, :business_account) do
        {nil, attrs} -> {insert(:business_account), attrs}
        {business_account, attrs} -> {business_account, attrs}
      end

    post = build(:post,
      Map.merge(%{
        business_id: business_account.id,
        business_name: business_account.first_name,
        business_admin_id: business_account.id,
        type: "offer",
        title: Faker.Lorem.word(),
        body: Faker.Lorem.sentence()
      }, attrs)
    )

    post =
      if attrs[:business_offer] || post.type != "offer" do
        post
      else
        %Post{post | business_offer: build(:business_offer, business: business_account, post: nil)}
      end

    post
  end

  def business_suggestion_factory do
    %BillBored.BusinessSuggestion{
      business: build(:business_account),
      suggestion: Faker.Lorem.sentence()
    }
  end

  def auth_token_factory do
    %User.AuthToken{
      key: Faker.String.base64(20),
      user: build(:user)
    }
  end

  def chat_room_factory do
    %Chat.Room{
      key: Faker.String.base64(10),
      title: Faker.Lorem.sentence(2),
      chat_type: "one-to-one",
      last_interaction: utc_now(),
      ghost_allowed: true,
      private: false
    }
  end

  def chat_message_interest_factory do
    %Chat.Message.Interest{
      message: build(:chat_message),
      interest: build(:interest)
    }
  end

  def location_factory(attrs) do
    struct!(BillBored.Geo.Point, attrs[:coordinates] || %{lat: 50, long: 50})
  end

  def user_interest_factory do
    %User.Interest{
      rating: 2,
      created: utc_now(),
      updated: utc_now(),
      user: build(:user),
      interest: build(:interest)
    }
  end

  def chat_message_hashtag_factory do
    %Chat.Message.Hashtag{
      message: build(:chat_message),
      hashtag: build(:hashtag)
    }
  end

  def chat_room_membership_factory do
    %Chat.Room.Membership{
      user: build(:user),
      room: build(:chat_room),
      role: "member"
    }
  end

  def chat_room_administratorship_factory do
    %Chat.Room.Administratorship{
      user: build(:user),
      room: build(:chat_room)
    }
  end

  def chat_room_elevated_privilege_factory do
    %Chat.Room.ElevatedPrivilege{
      user: build(:user),
      dropchat: build(:chat_room)
    }
  end

  def chat_room_elevated_privileges_request_factory do
    %Chat.Room.ElevatedPrivilege.Request{
      user: build(:user),
      room: build(:chat_room)
    }
  end

  def dropchat_ban_factory do
    %Chat.Room.DropchatBan{
      dropchat: build(:chat_room, chat_type: "dropchat"),
      admin: build(:user),
      banned_user: build(:user)
    }
  end

  def dropchat_stream_factory do
    %Chat.Room.DropchatStream{
      dropchat: build(:chat_room, chat_type: "dropchat"),
      admin: build(:user),
      key: Faker.String.base64(8),
      title: Faker.Lorem.sentence(1),
      status: "active"
    }
  end

  def dropchat_stream_speaker_factory do
    %Chat.Room.DropchatStream.Speaker{
      stream: build(:dropchat_stream),
      user: build(:user)
    }
  end

  def dropchat_stream_reaction_factory do
    %Chat.Room.DropchatStream.Reaction{
      stream: build(:dropchat_stream),
      user: build(:user)
    }
  end

  def post_factory(attrs) do
    location =
      case attrs[:location] do
        nil -> build(:location)
        [lat, lon] -> %BillBored.Geo.Point{long: lon, lat: lat}
        %BillBored.Geo.Point{} = point -> point
      end

    post = %Post{
      title: Faker.Lorem.sentence(1),
      body: Faker.Lorem.sentence(10),
      location: location,
      location_geohash:
        BillBored.Geo.Hash.to_integer(Geohash.encode(location.lat, location.long, 12)),
      private?: false,
      type: "regular",
      author: build(:user)
    }

    Map.merge(post, attrs)
  end

  def post_report_reason_factory do
    %PostReportReason{
      reason: ExMachina.Sequence.next(Faker.Lorem.word())
    }
  end

  def post_report_factory do
    %PostReport{
      post: build(:post),
      user: build(:user),
      reason: build(:post_report_reason)
    }
  end

  def post_approval_request_factory do
    %Post.ApprovalRequest{
      approver: build(:user),
      post: build(:post),
      requester: build(:user)
    }
  end

  def post_approval_request_rejection_factory do
    %Post.ApprovalRequest.Rejection{
      approver: build(:user),
      post: build(:post),
      requester: build(:user),
      note: Faker.Lorem.sentence(10)
    }
  end

  def poll_factory do
    %Poll{
      post: build(:post),
      question: Faker.Lorem.sentence(1),
      items: [%PollItem{title: "Yes"}, %PollItem{title: "Maybe"}, %PollItem{title: "No"}]
    }
  end

  def poll_item_factory do
    %PollItem{}
  end

  def poll_item_vote_factory do
    %PollItem.Vote{user: build(:user)}
  end

  def event_factory do
    %Event{
      title: Faker.Lorem.sentence(1),
      post: build(:post, type: "event"),
      date: DateTime.utc_now(),
      location: build(:location)
    }
  end

  def event_attendant_factory do
    %Event.Attendant{
      event: build(:event),
      status: "invited",
      user: build(:user)
    }
  end

  def event_synchronization_factory do
    %EventSynchronization{
      event_provider: "meetup",
      location: build(:location),
      started_at: DateTime.utc_now(),
      radius: Faker.random_between(1, 5) * 1_000
    }
  end

  def post_upvote_factory do
    %Post.Upvote{
      post: build(:post),
      user: build(:user)
    }
  end

  def post_downvote_factory do
    %Post.Downvote{
      post: build(:post),
      user: build(:user)
    }
  end

  def post_comment_factory do
    %Post.Comment{
      body: Faker.Lorem.sentence(1),
      post: build(:post),
      author: build(:user)
    }
  end

  def post_comment_upvote_factory do
    %Post.Comment.Upvote{
      comment: build(:post_comment),
      user: build(:user)
    }
  end

  def post_comment_downvote_factory do
    %Post.Comment.Downvote{
      comment: build(:post_comment),
      user: build(:user)
    }
  end

  def post_comment_interest_factory do
    %Post.Comment.Interest{
      comment: build(:post_comment),
      interest: build(:interest)
    }
  end

  def post_interest_factory do
    %Post.Interest{
      post: build(:post),
      interest: build(:interest)
    }
  end

  def place_factory do
    %Place{
      name: Faker.Lorem.sentence(3),
      place_id: Faker.String.base64(10),
      location: build(:location),
      address: Faker.Address.street_address(),
      icon: Faker.Avatar.image_url(),
      vicinity: Faker.Lorem.sentence(3)
    }
  end

  def interest_factory do
    %Interest{
      hashtag: Faker.String.base64(10),
      disabled?: false
    }
  end

  def hashtag_factory do
    %Hashtag{value: Faker.String.base64(10)}
  end

  def interest_category_factory do
    %InterestCategory{
      name: Faker.String.base64(10)
    }
  end

  def interest_category_interest_factory do
    %InterestCategoryInterest{
      interest: build(:interest),
      interest_category: build(:interest_category)
    }
  end

  def livestream_factory do
    %Livestream{
      title: Faker.Lorem.sentence(3),
      active?: false,
      recorded?: false,
      owner: build(:user)
    }
  end

  def livestream_comment_factory do
    %Livestream.Comment{
      body: Faker.Lorem.sentence(10),
      livestream: build(:livestream),
      author: build(:user)
    }
  end

  def notification_factory do
    %Notification{
      recipient: build(:user),
      level: "info",
      unread: true,
      deleted: false,
      emailed: false,
      public: false,
      description: Faker.Lorem.sentence(10),
      verb:
        Enum.random([
          "posts:new:popular",
          "dropchats:new:popular",
          "posts:like",
          "posts:reacted",
          "post:comments:like",
          "post:comments:reacted",
          "posts:comment",
          "posts:approve:request",
          "posts:approve:request:reject",
          "chats:privilege:granted",
          "chats:privilege:request"
        ]),
      actor_id: "",
      # 23 = chat  room
      actor_type: 9,
      timestamp: utc_now()
    }
  end

  def covid_location_factory do
    %BillBored.Covid.Location{
      source_location: build(:location),
      country_code: Faker.Address.country_code(),
      scope: "country",
      region: ""
    }
  end

  def covid_case_factory(attrs) do
    datetime = attrs[:datetime] || DateTime.utc_now()
    timeslot = attrs[:timeslot] || Timex.beginning_of_day(datetime) |> Timex.to_unix()

    covid_case = %BillBored.Covid.Case{
      datetime: datetime,
      timeslot: timeslot,
      location: build(:covid_location),
      cases: :rand.uniform(100_000),
      active_cases: :rand.uniform(50_000),
      deaths: :rand.uniform(10_000),
      recoveries: :rand.uniform(20_000)
    }

    Map.merge(covid_case, attrs)
  end

  def area_notification_factory do
    %BillBored.Notifications.AreaNotification{
      owner: build(:user),
      title: Faker.Lorem.word(),
      message: Faker.Lorem.sentence(1),
      location: build(:location),
      radius: :rand.uniform(9_999) + 1
    }
  end

  def area_notification_reception_factory do
    %BillBored.Notifications.AreaNotificationReception{
      user: build(:user),
      area_notification: build(:area_notification)
    }
  end

  def area_notifications_timetable_entry_factory do
    {:ok, time} = Time.new(Enum.random(0..23), Enum.random(0..59), 0)

    %BillBored.Notifications.AreaNotifications.TimetableEntry{
      time: time,
      categories: [],
      any_category: false,
      template: Faker.Lorem.sentence(1)
    }
  end

  def area_notifications_timetable_run_factory do
    %BillBored.Notifications.AreaNotifications.TimetableRun{
      area_notification: build(:area_notification),
      timetable_entry: build(:area_notifications_timetable_entry)
    }
  end

  def notification_area_notification_factory do
    %NotificationAreaNotification{
      notification: build(:notification, verb: "area_notifications:scheduled"),
      area_notification: build(:area_notification),
      timetable_run: build(:area_notifications_timetable_run)
    }
  end

  def user_recommendation_factory do
    %BillBored.User.Recommendation{
      user: build(:user),
      type: "autofollow"
    }
  end
end
