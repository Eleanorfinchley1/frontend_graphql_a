defmodule Web.Router do
  use Web, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :basic_auth do
    plug Web.Plugs.BasicAuth, username: "billbored", password: System.get_env("TORCH_PASSWORD")
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug Web.Plugs.Version
  end

  pipeline :context do
    plug(Web.Plugs.Context)
  end

  pipeline :context_with_restricted do
    plug(Web.Plugs.Context, allow_restricted: true)
  end

  pipeline :authenticated do
    plug(Web.Plugs.Authentication, allowed_registration_statuses: [:complete])
  end

  pipeline :authenticated_limited do
    plug(Web.Plugs.Authentication, allowed_registration_statuses: [:phone_verification_required, :complete])
  end

  pipeline :metrics do
    plug Web.Plugs.BasicAuth, config: {:billbored, :prometheus_basic_auth}
  end

  pipeline :torch_authorized do
    plug(Web.Plugs.TorchAuthorization)
  end

  pipeline :torch_authenticated do
    plug(Web.Plugs.TorchAuthentication)
  end

  scope "/metrics" do
    pipe_through :metrics

    forward "/", Metrics.Plug
  end

  scope "/search", Web do
    pipe_through(:browser)

    get("/search_example", SearchController, :example)
  end

  scope "/", Web do
    pipe_through :browser
    get("/", PageController, :index)
  end

  scope "/", Web, as: :browser do
    pipe_through :browser
    resources "/posts", PostController, only: [:show]
    resources "/events", EventController, only: [:show]
    resources "/livestreams", LivestreamController, only: [:show]
  end
  # json response for anyone
  scope "/api", Web do
    pipe_through :api

  end
  # json response for anyone, but user will be checkable
  scope "/api", Web do
    pipe_through([:context, :api])

    # user_feedback
    resources("/user_feedback", UserFeedbackController, except: [:edit, :new])

    # users
    resources("/user", UserController, only: [:create])

    # token
    post("/token", TokenController, :create_token)

    # Password reset
    post("/password_reset", AccountController, :password_reset)
    post("/change_password", AccountController, :change_password)

    # search user by
    post("/search-user", UserController, :search_user_by)

    post("/get_fake_location", GeoController, :show)

    # email verification
    get("/email-verification", AccountController, :email_verification)

    # university
    get "/university", UniversityController, :list
    get "/university/:id", UniversityController, :get
    post "/university", UniversityController, :create
    delete "/university/:id", UniversityController, :delete

    # mentor
    get "/mentor", MentorController, :list
    get "/mentor/:id", MentorController, :get
    post "/mentor/:user_id", MentorController, :create
    delete "/mentor/:id", MentorController, :delete

    # mentee
    get "/mentee", MentorController, :list_mentees
    get "/mentee/:id", MentorController, :get_mentee
    post "/mentee/:user_id/assign", MentorController, :assign_mentor
    # topic
    get "/topics", TopicController, :get
  end
  #
  scope "/api", Web do
    pipe_through([:context, :authenticated_limited, :api])

    # verification
    post("/phone-verification", AccountController, :phone_verification)
    post("/phone-verification-resend", AccountController, :phone_verification_resend)
    post("/email-verification-resend", AccountController, :email_verification_resend)

    # User routes
    resources "/user", UserController, only: [:update], singleton: true
    # TODO remove this route after the ios app is updated
    resources "/user", UserController, only: [:update], param: "user_name"
  end

  scope "/api", Web do
    pipe_through([:context_with_restricted, :authenticated, :api])

    # device
    resources("/device", DeviceController, except: [:edit, :new])
  end

  scope "/api", Web do
    pipe_through([:context, :authenticated, :api])

    # media
    delete("/media/:key", MediaController, :delete)

    # chats
    get("/rooms", ChatController, :index)
    post("/rooms", ChatController, :create)
    delete("/rooms/:id", ChatController, :delete)
    post("/rooms/:key/mute", ChatController, :mute)
    post("/rooms/:key/unmute", ChatController, :unmute)

    # membership
    put("/rooms/:id/member/:user_id", ChatController, :add_member)
    delete("/rooms/:id/member/:user_id", ChatController, :delete_member)

    #
    get("/follow-suggestions", FollowingController, :follow_suggestions)

    post("/close-friends", CloseFriendsController, :close_friends)

    # Livesteams routes
    resources("/livestreams", LivestreamController, only: [:create])
    post("/livestreams/:id/mark_recorded", LivestreamController, :mark_recorded)
    post("/livestreams/:id/publish", LivestreamController, :publish)

    get("/livestreams/:userid", LivestreamController, :find_user_livestreams)
    get("/livestreams", LivestreamController, :find_user_livestreams)

    delete("/livestreams/:id", LivestreamController, :delete_livestream)

    # DEPRECATED:
    delete("/livestreams/:id/:userid", LivestreamController, :delete_livestream)

    post(
      "/dropchats/elevated_privilege_requests/grant",
      DropchatController,
      :grant_request
    )

    ## NOTIFICATION ##

    get("/notifications", NotificationController, :index)
    post("/notifications", NotificationController, :update)

    ## SEARCH ##

    get("/search", SearchController, :search_all)

    ## USERS ##

    resources("/following", FollowingController, only: [:index, :create])

    get("/user/:id/following", FollowingController, :user_followings)

    get("/followers", FollowingController, :index_followers)
    get("/user/:id/followers", FollowingController, :user_followers)

    resources("/invites", InvitesController, only: [:index, :create])

    ## INTEREST ##

    get("/interests", InterestController, :index)
    get("/interest/:id", InterestController, :show)

    get("/interests/popular_interests", InterestController, :index)
    get("/interests/categories", InterestController, :categories)

    ## USER INTEREST ##

    get("/user_interests", UserInterestController, :list)
    post("/user_interests", UserInterestController, :create)
    delete("/user_interests/:id", UserInterestController, :delete)

    ## POST ##

    get("/posts", PostController, :index_for_user)
    get("/user/:id/posts", PostController, :index)

    get("/post/:id", PostController, :show)

    post("/post/:id", PostController, :vote)

    post("/posts", PostController, :create)
    put("/post/:id", PostController, :update)
    delete("/post/:id", PostController, :delete)

    post("/posts/approval/request", PostController, :request_approval)
    post("/posts/approval/approve", PostController, :approve_post)
    post("/posts/approval/reject", PostController, :reject_post)

    post("/posts/nearby", PostController, :list_nearby)

    ## POST COMMENT ##

    post("/post/:id/comments", PostCommentController, :create)

    get("/post/comment/:id", PostCommentController, :show)
    put("/post/comment/:id", PostCommentController, :update)
    delete("/post/comment/:id", PostCommentController, :delete)
    post("/post/comment/:id", PostCommentController, :vote)

    #
    post("/post/comment/:id/childs", PostCommentController, :create_child)

    get("/post/comment/:id/childs", PostCommentController, :index_childs)
    get("/post/:id/comments/top", PostCommentController, :index_top)
    get("/post/:id/comments", PostCommentController, :index)

    ## POLL ##

    post("/poll/:id/items", PollController, :add_item)
    put("/poll/item/:id/vote", PollController, :vote)

    delete("/poll/item/:id", PollController, :delete_item)
    delete("/poll/:id/items/votes", PollController, :unvote_all)

    post("/post/:id/polls", PollController, :create)
    delete("/poll/:id", PollController, :delete)
    get("/poll/:id", PollController, :show)
    put("/poll/:id", PollController, :update)

    ## EVENT ##

    put("/event/:id/attend/status", EventController, :set_status)
    put("/event/:id/invite", EventController, :invite)
    post("/event/:id/attend", EventController, :attend)
    post("/event/:id/refuse", EventController, :refuse)

    post("/post/:id/events", EventController, :create)
    delete("/event/:id", EventController, :delete)
    get("/event/:id", EventController, :show)
    put("/event/:id", EventController, :update)

    ## USER ##

    # User routes
    post("/profiles", UserController, :profiles_search)
    get("/profile/:user_name", UserController, :get_user_profile)

    get("/user", UserController, :get_user)
    delete("/user", UserController, :delete_temporarily)
    get("/user/:user_name", UserController, :get_user_profile)
    get("/users/:user_name", UserController, :search_users_by_username_like)
    post("/user/:blocked_user_id/block", UserController, :block_user)
    post("/user/:blocked_user_id/unblock", UserController, :unblock_user)
    get("/blocked_users", UserController, :get_blocked_users)
    get("/friends/:user_id", UserController, :index_friends_of_user)
    get("/friends", UserController, :index_friends)

    get("/users/:last_seen_param/:direction_param", UserController, :get_all_users)
    get("/businessAccounts/membersOf/:account_name", UserController, :get_all_members_of_account)
    get("/businessAccounts/adminsOf/:account_name", UserController, :get_all_admins_of_account)

    scope "/businessAccounts", BusinessAccounts, as: :business_accounts do
      get("/:business_id/stats", StatsController, :stats)
      get("/:business_id/stats/posts/:post_id/views", StatsController, :post_views)
      get("/:business_id/stats/posts/:post_id/stats", StatsController, :post_stats)
      get("/:business_id/followers_history", FollowersController, :history)
    end

    get("/businessAccounts/:id", UserController, :show_business_account)
    get("/businessAccounts/:id/posts", PostController, :list_business_posts)

    get("/businessAccounts/:business_id/area_notifications", AreaNotificationController, :list_business_area_notifications)
    post("/businessAccounts/:business_id/area_notifications", AreaNotificationController, :create_business_area_notification)
    delete("/businessAccounts/:business_id/area_notifications/:id", AreaNotificationController, :delete_business_area_notification)

    get(
      "/businessAccounts/:last_seen_param/:direction_param",
      UserController,
      :get_all_busisness_account
    )

    get("/user/businessAccounts/:user_name", UserController, :get_business_account_from_user)

    post("/businessAccounts/create", UserController, :create_business_account)

    put("/businessAccounts/:business_id", UserController, :update_business_account)
    put("/businessAccounts/manage/addMembers", UserController, :add_members_to_business_account)

    put(
      "/businessAccounts/changeMemberRole",
      UserController,
      :change_member_role_on_business_account
    )

    delete("/businessAccounts/removeMember", UserController, :remove_member_from_business_account)
    delete("/businessAccounts/closeUserAccount", UserController, :close_business_user_account)
    delete("/businessAccounts/closeBusinessAccount", UserController, :close_business_account)

    ## REPORT ##

    get("/report/reasons", PostReportController, :get_all_post_report_reason)
    post("/report/post", PostReportController, :create_post_report)

    # Business category
    get(
      "/business/categories/:last_seen_param/:direction_param",
      BusinessController,
      :get_paginate_categories
    )

    post("/business/category/create", BusinessController, :create_business_category)
    post("/business/category/add", BusinessController, :add_business_categories)

    post("/drop_chat_feed", DropchatController, :dropchat_feed)
    post("/dropchat_list", DropchatController, :dropchat_list)
    get("/stream_recordings", DropchatController, :user_stream_recordings)
    delete("/stream_recordings/:stream_id", DropchatController, :remove_stream_recordings)

    resources("/messages", MessageController, except: [:edit, :new])

    post("/chat_search", ChatController, :chat_search)

    # COVID-19

    get("/covid/cases/by_country", CovidController, :list_by_country)
    get("/covid/cases/by_region", CovidController, :list_by_region)

    # POINT Request
    post("/point_requests", PointRequestController, :create)
    post("/point_requests/:request_id/send", PointRequestController, :donate)

    # LeaderBoard
    get("/leaderboard", LeaderboardController, :show)
  end

  scope "/nginx", Web do
    post("/publish", NGINXController, :publish)
    post("/publish_done", NGINXController, :publish_done)
  end

  scope "/api/media", Web do
    pipe_through([:context, :authenticated, :api])

    post("/upload", MediaController, :upload)
    post("/get_links", MediaController, :get_links)
  end

  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end

  # scope torch apis callable without auth
  scope "/api/torch", Web, as: :torch_api do
    pipe_through [:api]

    post("/auth_token", Torch.API.AdminController, :auth_token)
    get("/accept_invite", Torch.API.AdminController, :accept_invitation)
    post("/verify_token", Torch.API.AdminController, :verify_token) # For testing
  end

  # scope torch api callable with auth
  scope "/api/torch", Web, as: :torch_authorized_api do
    pipe_through [:torch_authorized, :api]

    post("/change_password", Torch.API.AdminController, :change_password)
    post("/update", Torch.API.AdminController, :update)
    get("/show", Torch.API.AdminController, :show)
    get("/users_activities", Torch.UserController, :index_with_activities)

    get("/permissions/list", Torch.API.AdminPermissionController, :list)
    get("/permissions/tree", Torch.API.AdminPermissionController, :tree)

    get("/interests/list", Torch.API.InterestController, :list)

    post("/users/nearby", Torch.API.UserController, :list_nearby)
    get("/users/list", Torch.API.UserController, :list)
  end

  # scope torch api checkable permissions
  scope "/api/torch", Web, as: :torch_authenticated_api do
    pipe_through [:torch_authorized, :torch_authenticated, :api]

    post("/admins", Torch.API.AdminController, :register_and_invite)
    post("/admin/:id/reset", Torch.API.AdminController, :reset_account)
    post("/admin/:id/ban", Torch.API.AdminController, :ban_account)
    post("/admin/:id/roles", Torch.API.AdminController, :assign_roles)
    put("/admin/:id", Torch.API.AdminController, :update_account)
    get("/admin/:id", Torch.API.AdminController, :show_account)
    get("/admins", Torch.API.AdminController, :index)

    get("/roles", Torch.API.AdminRoleController, :index)
    get("/roles/list", Torch.API.AdminRoleController, :all)
    post("/roles", Torch.API.AdminRoleController, :create)
    put("/role/:id", Torch.API.AdminRoleController, :update)
    delete("/role/:id", Torch.API.AdminRoleController, :delete)
    get("/role/:id", Torch.API.AdminRoleController, :show)

    get("/posts", Torch.API.PostController, :index)
    post("/posts", Torch.API.PostController, :create)
    get("/post/:id", Torch.API.PostController, :show)
    put("/post/:id", Torch.API.PostController, :update)
    delete("/post/:id", Torch.API.PostController, :delete)

    get("/interests", Torch.API.InterestController, :index)
    post("/interests", Torch.API.InterestController, :create)
    get("/interest/:id", Torch.API.InterestController, :show)
    put("/interest/:id", Torch.API.InterestController, :update)
    delete("/interest/:id", Torch.API.InterestController, :delete)
  end

  scope "/torch", Web, as: :torch do
    pipe_through [:browser, :basic_auth]

    resources "/posts", Torch.PostController, only: [:index, :show, :delete]
    get("/posts_for_review", Torch.PostController, :index_for_review)
    post("/posts_for_review/:id/approve", Torch.PostController, :approve_post_review)
    post("/posts_for_review/:id/reject", Torch.PostController, :reject_post_review)

    resources "/post_report_reasons", Torch.PostReportReasonController

    resources "/users", Torch.UserController, only: [:index, :show]
    post("/users/:id/ban", Torch.UserController, :ban_user)
    post("/users/:id/unban", Torch.UserController, :unban_user)
    post("/users/:id/restrict_access", Torch.UserController, :restrict_access)
    post("/users/:id/grant_access", Torch.UserController, :grant_access)

    get("/covid_info", Torch.CovidInfoController, :show)
    get("/covid_info/edit", Torch.CovidInfoController, :edit)
    post("/covid_info", Torch.CovidInfoController, :update)

    get("/access_restriction_policy", Torch.AccessRestrictionPolicyController, :show)
    get("/access_restriction_policy/edit", Torch.AccessRestrictionPolicyController, :edit)
    post("/access_restriction_policy", Torch.AccessRestrictionPolicyController, :update)

    resources "/business_accounts", Torch.BusinessAccountController, only: [:index, :show, :edit, :update]

    resources "/area_notifications", Torch.AreaNotificationController,
      only: [:index, :show, :new, :create, :delete]

    resources "/timetable_entries", Torch.TimetableEntryController,
      only: [:index, :show, :new, :create, :edit, :update, :delete]

    resources "/user_recommendations", Torch.UserRecommendationController,
      only: [:index, :create, :delete]

    resources "/interest_categories", Torch.InterestCategoryController

    resources "/location_rewards", Torch.LocationRewardController,
      only: [:index, :show, :new, :create, :delete]

    get("/location_rewards/:location_reward_id/notify", Torch.LocationRewardController, :pre_notify)
    post("/location_rewards/:location_reward_id/notify", Torch.LocationRewardController, :notify)
  end
end
