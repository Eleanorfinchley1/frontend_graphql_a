defmodule Web.UserControllerTest do
  use Web.ConnCase, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Ecto.Query
  import BillBored.ServiceRegistry, only: [replace: 2]

  alias BillBored.{User, User.Block}

  setup_all do
    HTTPoison.start()
  end

  @valid_params %{
    "area" => "East Judd",
    "bio" => "Blanditiis nesciunt nesciunt voluptatem qui facilis nemo quod excepturi ut.",
    "birthdate" => "1976-05-25",
    "country_code" => "38",
    "date_joined" => "2019-05-03T18:23:29.414351Z",
    "email" => "litzy.beatty@hayes.info",
    "enable_push_notifications" => false,
    "first_name" => "Loy",
    "last_name" => "Hills",
    "phone" => "9774759105",
    "prefered_radius" => 1,
    "sex" => "m",
    "user_real_location" => nil,
    "user_safe_location" => nil,
    "user_tags" => [],
    "username" => "user",
    "password" => "PASSWORD",
    "verified_phone" => ""
  }

  defmodule Stubs.PhoneVerification do
    def start(_), do: {:ok, %{message: "Your code is 1234"}}
  end

  describe "user create" do
    test "with valid params", %{conn: conn} = _context do
      use_cassette "authy_sms" do
        conn
        |> post(Routes.user_path(conn, :create), @valid_params)
        |> response(200)
      end
    end

    test "returns 422 if phone number is already used", %{conn: conn} = _context do
      replace(PhoneVerification, Stubs.PhoneVerification)

      insert(:user, country_code: "44", phone: "12345", verified_phone: "12345")

      assert %{
               "reason" => %{
                 "phone" => ["has already been taken"]
               },
               "success" => false
             } =
               conn
               |> post(Routes.user_path(conn, :create), Map.merge(@valid_params, %{
                 "country_code" => "44",
                 "phone" => "12345"
               }))
               |> json_response(422)
    end
  end

  describe "users update" do
    test "only himself", %{conn: conn} do
      [token1, token2] = insert_list(2, :auth_token)

      conn
      |> authenticate(token1.key)
      |> put(Routes.user_path(conn, :update, token2.user.username, %{}))
      |> response(403)
    end

    test "with valid params", %{conn: conn} do
      %{key: token} = insert(:auth_token)
      conn = authenticate(conn, token)

      assert %{
               "avatar" => new_avatar,
               "avatar_thumbnail" => new_avatar_thumbnail,
               "bio" => "new bio",
               "email" => "new@email.com"
             } =
               conn
               |> patch(Routes.user_path(conn, :update), %{
                 "avatar" => "new_avatar_path",
                 "avatar_thumbnail" => "new_avatar_thumbnail_path",
                 "bio" => "new bio",
                 "email" => "new@email.com"
               })
               |> json_response(200)

      assert String.contains?(new_avatar, "new_avatar_path")
      assert String.contains?(new_avatar_thumbnail, "new_avatar_thumbnail_path")
    end

    test "updates phone number", %{conn: conn} do
      replace(PhoneVerification, Stubs.PhoneVerification)

      %{key: token, user_id: user_id} = insert(:auth_token)
      conn = authenticate(conn, token)

      assert %{
               "country_code" => "44",
               "phone" => "12345"
             } =
               conn
               |> patch(Routes.user_path(conn, :update), %{
                 "country_code" => "44",
                 "phone" => "12345"
               })
               |> json_response(200)

      assert %{country_code: "44", phone: "12345"} = Repo.get(BillBored.User, user_id)
    end

    test "returns error when phone number is already used", %{conn: conn} do
      replace(PhoneVerification, Stubs.PhoneVerification)

      insert(:user, country_code: "44", phone: "12345", verified_phone: "12345")

      %{key: token} = insert(:auth_token)
      conn = authenticate(conn, token)

      assert %{
               "errors" => %{
                 "phone" => ["has already been taken"]
               },
               "success" => false
             } =
               conn
               |> patch(Routes.user_path(conn, :update), %{
                 "country_code" => "44",
                 "phone" => "12345"
               })
               |> json_response(400)
    end

    test "allows to use same phone in different country code", %{conn: conn} do
      replace(PhoneVerification, Stubs.PhoneVerification)

      insert(:user, country_code: "1", phone: "12345", verified_phone: "12345")

      %{key: token} = insert(:auth_token)
      conn = authenticate(conn, token)

      assert %{
               "country_code" => "44",
               "phone" => "12345"
             } =
               conn
               |> patch(Routes.user_path(conn, :update), %{
                 "country_code" => "44",
                 "phone" => "12345"
               })
               |> json_response(200)
    end

    test "allows to use same phone as unverified", %{conn: conn} do
      replace(PhoneVerification, Stubs.PhoneVerification)

      insert(:user, country_code: "44", phone: "12345", verified_phone: nil)

      %{key: token} = insert(:auth_token)
      conn = authenticate(conn, token)

      assert %{
               "country_code" => "44",
               "phone" => "12345"
             } =
               conn
               |> patch(Routes.user_path(conn, :update), %{
                 "country_code" => "44",
                 "phone" => "12345"
               })
               |> json_response(200)
    end
  end

  describe "create_business_account" do
    test "creates business account", %{conn: conn} do
      admin = %{id: admin_id} = insert(:user)
      user = %{id: user_id} = insert(:user)
      %{key: token} = insert(:auth_token, user: user)
      conn = authenticate(conn, token)

      category = insert(:business_category, category_name: "food")

      assert %{
               "business_account_name" => "KFC",
               "business_account_user_name" => "kfc_corporate",
               "categories" => [%{"category" => "food", "id" => _}],
               "id" => business_account_id,
               "email" => "corporate@kfc.com",
               "avatar" => "https://placekitten.com/420/360",
               "avatar_thumbnail" => "https://placekitten.com/60/60",
               "location" => %{
                 "coordinates" => [30.7008, 76.7885],
                 "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                 "type" => "Point"
               }
             } =
               conn
               |> post(Routes.user_path(conn, :create_business_account), %{
                 "business_account_username" => "kfc_corporate",
                 "business_account_name" => "KFC",
                 "email" => "corporate@kfc.com",
                 "location" => [30.7008, 76.7885],
                 "referral_code" => "CODE0123",
                 "admin_user" => admin.username,
                 "avatar" => "https://placekitten.com/420/360",
                 "avatar_thumbnail" => "https://placekitten.com/60/60",
                 "categories_to_add" => [
                   %{"business_category_id" => category.id}
                 ]
               })
               |> json_response(200)

      assert %BillBored.User{
               username: "kfc_corporate",
               first_name: "KFC",
               email: "corporate@kfc.com",
               user_real_location: %BillBored.Geo.Point{lat: 30.7008, long: 76.7885},
               referral_code: "CODE0123",
               business_category: [
                 %{category_name: "food"}
               ]
             } =
               business_account =
               Repo.get(BillBored.User, business_account_id)
               |> Repo.preload([:business_category, :members])

      assert [
               %{role: "admin", member_id: ^admin_id},
               %{role: "owner", member_id: ^user_id}
             ] =
               User.Memberships.membership_of(business_account)
               |> Enum.sort_by(fn %{role: role} -> role end)
    end

    test "creates business account when owner is the admin_user", %{conn: conn} do
      user = %{id: user_id} = insert(:user)
      %{key: token} = insert(:auth_token, user: user)
      conn = authenticate(conn, token)

      assert %{
               "id" => business_account_id
             } =
               conn
               |> post(Routes.user_path(conn, :create_business_account), %{
                 "business_account_username" => "kfc_corporate",
                 "business_account_name" => "KFC",
                 "email" => "corporate@kfc.com",
                 "location" => [30.7008, 76.7885],
                 "admin_user" => user.username,
                 "avatar" => "https://placekitten.com/420/360",
                 "avatar_thumbnail" => "https://placekitten.com/60/60",
                 "categories_to_add" => []
               })
               |> json_response(200)

      assert %BillBored.User{
               username: "kfc_corporate",
               first_name: "KFC",
               email: "corporate@kfc.com"
             } =
               business_account =
               Repo.get(BillBored.User, business_account_id)
               |> Repo.preload([:business_category, :members])

      assert [
               %{role: "owner", member_id: ^user_id}
             ] = User.Memberships.membership_of(business_account)
    end

    test "returns error if admin user is not found", %{conn: conn} do
      %{key: token} = insert(:auth_token)
      conn = authenticate(conn, token)

      assert %{
               "error" => "user_not_found",
               "reason" => "user_not_found",
               "success" => false
             } =
               conn
               |> post(Routes.user_path(conn, :create_business_account), %{
                 "business_account_username" => "kfc_corporate",
                 "business_account_name" => "KFC",
                 "email" => "corporate@kfc.com",
                 "location" => [30.7008, 76.7885],
                 "admin_user" => "invalid",
                 "avatar" => "https://placekitten.com/420/360",
                 "avatar_thumbnail" => "https://placekitten.com/60/60",
                 "categories_to_add" => []
               })
               |> json_response(422)
    end

    test "returns error if username is taken", %{conn: conn} do
      user = insert(:user)
      %{key: token} = insert(:auth_token, user: user)
      conn = authenticate(conn, token)

      _squatter = insert(:user, username: "kfc_corporate")

      assert %{
               "reason" => %{
                 "nickname" => ["has already been taken"]
               },
               "success" => false
             } =
               conn
               |> post(Routes.user_path(conn, :create_business_account), %{
                 "business_account_username" => "kfc_corporate",
                 "business_account_name" => "KFC",
                 "email" => "corporate@kfc.com",
                 "location" => [30.7008, 76.7885],
                 "admin_user" => user.username,
                 "avatar" => "https://placekitten.com/420/360",
                 "avatar_thumbnail" => "https://placekitten.com/60/60",
                 "categories_to_add" => []
               })
               |> json_response(422)
    end

    test "returns error if not params are passed", %{conn: conn} do
      user = insert(:user)
      %{key: token} = insert(:auth_token, user: user)
      conn = authenticate(conn, token)

      assert %{
               "error" => "missing_required_params",
               "reason" =>
                 "Missing required params: email, avatar_thumbnail, avatar, business_account_username",
               "success" => false
             } =
               conn
               |> post(Routes.user_path(conn, :create_business_account), %{
                 "business_account_name" => "KFC",
                 "location" => [30.7008, 76.7885],
                 "admin_user" => user.username,
                 "categories_to_add" => []
               })
               |> json_response(422)
    end
  end

  describe "show business account" do
    setup do
      business_account = insert(:business_account)
      food = insert(:business_category, category_name: "food")
      insert(:businesses_categories, business_category: food, user: business_account)

      member = insert(:user)
      insert(:user_membership, member: member, role: "member", business_account: business_account)
      owner = insert(:user)
      insert(:user_membership, member: owner, role: "owner", business_account: business_account)

      %{
        business_account: business_account,
        owner: owner,
        member: member
      }
    end

    test "shows business account to owner", %{
      conn: conn,
      owner: owner,
      business_account: %{id: id} = business_account
    } do
      insert(:business_suggestion, business: business_account, suggestion: "Smile more!")

      assert %{
               "avatar" => _,
               "avatar_thumbnail" => _,
               "business_account_name" => _,
               "business_account_user_name" => _,
               "categories" => [%{"category" => "food", "id" => _}],
               "email" => _,
               "id" => ^id,
               "last_name" => _,
               "location" => %{
                 "coordinates" => [40.0, 30.0],
                 "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                 "type" => "Point"
               },
               "followers_count" => 0,
               "suggestion" => "Smile more!"
             } =
               conn
               |> authenticate(insert(:auth_token, user: owner).key)
               |> get(Routes.user_path(conn, :show_business_account, business_account.id))
               |> doc()
               |> json_response(200)
    end

    test "shows business account to member", %{
      conn: conn,
      member: member,
      business_account: %{id: id} = business_account
    } do
      assert %{
               "avatar" => _,
               "avatar_thumbnail" => _,
               "business_account_name" => _,
               "business_account_user_name" => _,
               "categories" => [%{"category" => "food", "id" => _}],
               "email" => _,
               "id" => ^id,
               "last_name" => _,
               "location" => %{
                 "coordinates" => [40.0, 30.0],
                 "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                 "type" => "Point"
               },
               "followers_count" => 0,
               "suggestion" => nil
             } =
               conn
               |> authenticate(insert(:auth_token, user: member).key)
               |> get(Routes.user_path(conn, :show_business_account, business_account.id))
               |> json_response(200)
    end

    test "does not show business account to another user", %{
      conn: conn,
      business_account: business_account
    } do
      conn
      |> authenticate(insert(:auth_token).key)
      |> get(Routes.user_path(conn, :show_business_account, business_account.id))
      |> response(403)
    end

    test "returns correct number of followers", %{
      conn: conn,
      member: member,
      business_account: business_account
    } do
      Enum.each(1..5, fn _ ->
        insert(:user_following, from: insert(:user), to: business_account)
      end)

      assert %{
               "followers_count" => 5
             } =
               conn
               |> authenticate(insert(:auth_token, user: member).key)
               |> get(Routes.user_path(conn, :show_business_account, business_account.id))
               |> json_response(200)
    end
  end

  describe "#block_user" do
    setup do
      token = insert(:auth_token)
      another_user = insert(:user)
      %{user: token.user, another_user: another_user, token: token}
    end

    test "blocks specified user for current user", %{
      conn: conn,
      user: current_user,
      another_user: another_user,
      token: token
    } do
      assert "" ==
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :block_user, another_user.id))
               |> response(200)

      assert %Block{} =
               from(b in Block,
                 where:
                   b.to_userprofile_id == ^current_user.id and
                     b.from_userprofile_id == ^another_user.id
               )
               |> Repo.one!()
    end

    test "returns 404 if attempting to block invalid user", %{
      conn: conn,
      token: token
    } do
      assert %{"error" => "Page not found"} ==
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :block_user, 0))
               |> json_response(404)
    end

    test "return 422 if attempting to block superuser", %{
      conn: conn,
      token: token
    } do
      superuser = insert(:user, is_superuser: true)

      assert %{"error" => "cannot_block_superuser", "success" => false} =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :block_user, superuser.id))
               |> json_response(422)
    end

    test "return 422 if attempting to block self", %{
      conn: conn,
      token: token,
      user: user
    } do
      assert %{"error" => "cannot_block_self", "success" => false} =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :block_user, user.id))
               |> json_response(422)
    end
  end

  describe "#unblock_user" do
    setup do
      token = insert(:auth_token)
      another_user = insert(:user)
      block = insert(:user_block, blocker: token.user, blocked: another_user)
      %{user: token.user, another_user: another_user, token: token, block: block}
    end

    test "unblocks specified user for current user", %{
      conn: conn,
      another_user: another_user,
      token: token,
      block: block
    } do
      assert "" ==
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :unblock_user, another_user.id))
               |> response(200)

      assert is_nil(from(b in Block, where: b.id == ^block.id) |> Repo.one())
    end

    test "returns 200 if user isn't blocked", %{
      conn: conn,
      another_user: another_user,
      token: token,
      block: block
    } do
      Repo.delete!(block)
      assert is_nil(from(b in Block, where: b.id == ^block.id) |> Repo.one())

      assert "" ==
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :unblock_user, another_user.id))
               |> response(200)
    end

    test "returns 404 if attempting to unblock invalid user", %{
      conn: conn,
      token: token
    } do
      assert %{"error" => "Page not found"} ==
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :block_user, 0))
               |> json_response(404)
    end
  end

  describe "#get_blocked_users" do
    setup do
      token = insert(:auth_token)
      block1 = insert(:user_block, blocker: token.user)
      block2 = insert(:user_block, blocker: token.user)
      block3 = insert(:user_block, blocker: token.user)
      blocked_users = [block1, block2, block3] |> Enum.map(& &1.blocked) |> Enum.sort_by(& &1.id)

      %{user: token.user, token: token, blocked_users: blocked_users}
    end

    test "returns blocked users for current user", %{
      conn: conn,
      token: token,
      blocked_users: blocked_users
    } do
      response =
        conn
        |> authenticate(token.key)
        |> get(Routes.user_path(conn, :get_blocked_users))
        |> json_response(200)

      ids = response |> Enum.map(& &1["id"]) |> Enum.sort()
      assert ids == blocked_users |> Enum.map(& &1.id)
    end
  end

  def create_users(_context) do
    u1 = insert(:user, username: "shy_dodo")
    u2 = insert(:user, username: "dodolover")
    u3 = insert(:user, username: "dodocatcher")
    u4 = insert(:user, username: "superman")
    insert(:user, username: "banned_dodo", banned?: true)

    users = [u1, u2, u3, u4]

    for {u, i} <- users |> Enum.zip(["jogging", "tennis", "swimming", "crocheting"]) do
      insert(:user_interest, user: u, interest: insert(:interest, hashtag: i))
    end

    %{users: users}
  end

  describe "search_users_by_username_like" do
    setup :create_users

    setup do
      token = insert(:auth_token)
      %{token: token}
    end

    test "returns matching users", %{conn: conn, token: token, users: users} do
      response =
        conn
        |> authenticate(token.key)
        |> get(Routes.user_path(conn, :search_users_by_username_like, "dodo"))
        |> json_response(200)

      matching_users = users |> Enum.take(3)

      assert matching_users |> Enum.map(& &1.username) |> Enum.sort() ==
               response |> Enum.map(& &1["username"]) |> Enum.sort()
    end

    test "does not return users who blocked us", %{conn: conn, token: token, users: [u1 | users]} do
      insert(:user_block, blocker: u1, blocked: token.user)

      response =
        conn
        |> authenticate(token.key)
        |> get(Routes.user_path(conn, :search_users_by_username_like, "dodo"))
        |> json_response(200)

      matching_users = users |> Enum.take(2)

      assert matching_users |> Enum.map(& &1.username) |> Enum.sort() ==
               response |> Enum.map(& &1["username"]) |> Enum.sort()
    end

    test "does not return blocked users", %{conn: conn, token: token, users: [u1 | users]} do
      insert(:user_block, blocked: u1, blocker: token.user)

      response =
        conn
        |> authenticate(token.key)
        |> get(Routes.user_path(conn, :search_users_by_username_like, "dodo"))
        |> json_response(200)

      matching_users = users |> Enum.take(2)

      assert matching_users |> Enum.map(& &1.username) |> Enum.sort() ==
               response |> Enum.map(& &1["username"]) |> Enum.sort()
    end
  end

  describe "profiles_search" do
    setup :create_users

    setup do
      token = insert(:auth_token)
      %{token: token}
    end

    test "returns matching users", %{
      conn: conn,
      token: token,
      users: [%User{username: u1_username} = u1 | _rest]
    } do
      assert [%{"results" => [%{"username" => ^u1_username}]}] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{
                 "search" => %{"country_code" => "", "phone" => u1.phone}
               })
               |> json_response(200)

      assert [%{"results" => [%{"username" => ^u1_username}]}] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => [u1.phone]})
               |> json_response(200)

      assert [%{"results" => [%{"username" => ^u1_username}]}, _] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => u1_username})
               |> json_response(200)

      assert [_, %{"results" => [%{"username" => ^u1_username}]}] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => u1.first_name})
               |> json_response(200)

      assert [%{"results" => [%{"username" => ^u1_username}]}] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{
                 "search" => "jogging",
                 "fields" => ["interests"]
               })
               |> json_response(200)
    end

    test "does not return user who blocked us", %{
      conn: conn,
      token: token,
      users: [%User{username: u1_username} = u1 | _rest]
    } do
      insert(:user_block, blocker: u1, blocked: token.user)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{
                 "search" => %{"country_code" => "", "phone" => u1.phone}
               })
               |> json_response(200)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => [u1.phone]})
               |> json_response(200)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => u1_username})
               |> json_response(200)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => u1.first_name})
               |> json_response(200)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{
                 "search" => "jogging",
                 "fields" => ["interests"]
               })
               |> json_response(200)
    end

    test "does not return blocked user", %{
      conn: conn,
      token: token,
      users: [%User{username: u1_username} = u1 | _rest]
    } do
      insert(:user_block, blocker: token.user, blocked: u1)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{
                 "search" => %{"country_code" => "", "phone" => u1.phone}
               })
               |> json_response(200)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => [u1.phone]})
               |> json_response(200)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => u1_username})
               |> json_response(200)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => u1.first_name})
               |> json_response(200)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{
                 "search" => "jogging",
                 "fields" => ["interests"]
               })
               |> json_response(200)
    end

    test "does not return banned user", %{
      conn: conn,
      token: token,
      users: [%User{username: u1_username} = u1 | _rest]
    } do
      from(u in User, where: u.id == ^u1.id, update: [set: [banned?: true]])
      |> Repo.update_all([])

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{
                 "search" => %{"country_code" => "", "phone" => u1.phone}
               })
               |> json_response(200)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => [u1.phone]})
               |> json_response(200)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => u1_username})
               |> json_response(200)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => u1.first_name})
               |> json_response(200)

      assert [] =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{
                 "search" => "jogging",
                 "fields" => ["interests"]
               })
               |> json_response(200)
    end
  end

  describe "index_friends_of_user" do
    setup :create_users

    setup do
      token = insert(:auth_token)
      %{token: token}
    end

    test "returns user's friends", %{conn: conn, token: token, users: users} do
      friendly_user = insert(:user)

      for u <- users do
        insert_user_friendship(users: [friendly_user, u])
      end

      response =
        conn
        |> authenticate(token.key)
        |> get(Routes.user_path(conn, :index_friends_of_user, friendly_user.id))
        |> json_response(200)

      assert response["entries"] |> Enum.map(& &1["id"]) |> Enum.sort() ==
               users |> Enum.map(& &1.id) |> Enum.sort()
    end
  end

  describe "get_all_users" do
    setup :create_users

    setup do
      token = insert(:auth_token)
      %{token: token}
    end

    test "returns users in order", %{conn: conn, token: token, users: [u1, u2, u3, u4]} do
      response =
        conn
        |> authenticate(token.key)
        |> get(Routes.user_path(conn, :get_all_users, "0", "next"))
        |> json_response(200)

      assert [u1.id, u2.id, u3.id, u4.id, token.user.id] == response |> Enum.map(& &1["id"])
    end

    test "does not return users who blocked us", %{
      conn: conn,
      token: token,
      users: [u1, u2, u3, u4]
    } do
      insert(:user_block, blocker: u3, blocked: token.user)

      response =
        conn
        |> authenticate(token.key)
        |> get(Routes.user_path(conn, :get_all_users, "0", "next"))
        |> json_response(200)

      assert [u1.id, u2.id, u4.id, token.user.id] == response |> Enum.map(& &1["id"])
    end

    test "does not return blocked users", %{conn: conn, token: token, users: [u1, u2, u3, u4]} do
      insert(:user_block, blocked: u2, blocker: token.user)

      response =
        conn
        |> authenticate(token.key)
        |> get(Routes.user_path(conn, :get_all_users, "0", "next"))
        |> json_response(200)

      assert [u1.id, u3.id, u4.id, token.user.id] == response |> Enum.map(& &1["id"])
    end
  end

  describe "get_user_profile" do
    setup do
      token = insert(:auth_token)
      %{token: token, user: insert(:user)}
    end

    test "returns user profile", %{conn: conn, token: token, user: %User{id: user_id} = user} do
      response =
        conn
        |> authenticate(token.key)
        |> get(Routes.user_path(conn, :get_user_profile, user.username))
        |> json_response(200)

      assert %{"id" => ^user_id} = response
    end

    test "returns 404 if user blocked us", %{conn: conn, token: token, user: user} do
      insert(:user_block, blocker: user, blocked: token.user)

      assert %{"error" => "Page not found"} ==
               conn
               |> authenticate(token.key)
               |> get(Routes.user_path(conn, :get_user_profile, user.username))
               |> json_response(404)
    end

    test "returns 404 if user is blocked by us", %{conn: conn, token: token, user: user} do
      insert(:user_block, blocked: user, blocker: token.user)

      assert %{"error" => "Page not found"} ==
               conn
               |> authenticate(token.key)
               |> get(Routes.user_path(conn, :get_user_profile, user.username))
               |> json_response(404)
    end
  end

  describe "when current user is banned" do
    setup do
      token = insert(:auth_token, user: insert(:user, banned?: true))
      %{token: token}
    end

    test "methods return 403", %{conn: conn, token: token} do
      assert %{"success" => false, "error" => "banned"} =
               conn
               |> authenticate(token.key)
               |> get(Routes.user_path(conn, :get_user_profile, "test"))
               |> json_response(403)

      assert %{"success" => false, "error" => "banned"} =
               conn
               |> authenticate(token.key)
               |> get(Routes.user_path(conn, :get_all_users, "0", "next"))
               |> json_response(403)

      assert %{"success" => false, "error" => "banned"} =
               conn
               |> authenticate(token.key)
               |> get(Routes.user_path(conn, :index_friends_of_user, token.user.id))
               |> json_response(403)

      assert %{"success" => false, "error" => "banned"} =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => "test"})
               |> json_response(403)
    end
  end

  describe "when current user access is restricted" do
    setup do
      token =
        insert(:auth_token,
          user:
            insert(:user,
              flags: %{"access" => "restricted", "restriction_reason" => "a valid reason"}
            )
        )

      %{token: token}
    end

    test "methods return 403", %{conn: conn, token: token} do
      assert %{"success" => false, "error" => "access_restricted", "reason" => "a valid reason"} =
               conn
               |> authenticate(token.key)
               |> get(Routes.user_path(conn, :get_user_profile, "test"))
               |> json_response(403)

      assert %{"success" => false, "error" => "access_restricted", "reason" => "a valid reason"} =
               conn
               |> authenticate(token.key)
               |> get(Routes.user_path(conn, :get_all_users, "0", "next"))
               |> json_response(403)

      assert %{"success" => false, "error" => "access_restricted", "reason" => "a valid reason"} =
               conn
               |> authenticate(token.key)
               |> get(Routes.user_path(conn, :index_friends_of_user, token.user.id))
               |> json_response(403)

      assert %{"success" => false, "error" => "access_restricted", "reason" => "a valid reason"} =
               conn
               |> authenticate(token.key)
               |> post(Routes.user_path(conn, :profiles_search), %{"search" => "test"})
               |> json_response(403)
    end
  end
end
