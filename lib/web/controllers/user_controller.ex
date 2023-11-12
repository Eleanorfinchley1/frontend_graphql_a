defmodule Web.UserController do
  use Web, :controller
  alias BillBored.{User, Users, UserPoints, Users.Referrals}
  alias BillBored.User.Blocks, as: UserBlocks
  require Logger

  import BillBored.ServiceRegistry, only: [service: 1]

  action_fallback(Web.FallbackController)

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def get_user(conn, _params, user_id) do
    user = Users.get_by_id!(user_id)
    render(conn, "custom_user.json", user: user)
  end

  def search_users_by_username_like(
        %{assigns: %{user_id: user_id}} = conn,
        %{"user_name" => user_name},
        _opts
      ) do
    case BillBored.Users.search_user_by_name_like_criteria(user_name, %{for_id: user_id}) do
      [] ->
        # TODO return 200 with empty list
        conn
        |> put_status(404)
        |> json(%{message: "No users found!"})

      users ->
        render(conn, "list.json", users: users)
    end
  end

  # TODO what is this used for?
  def search_user_by(conn, %{"username" => username}, _opts) do
    exist? = !!Users.get_by(username: username)
    json(conn, %{username: exist?})
  end

  def search_user_by(conn, %{"phone" => phone}, _opts) do
    exist? = !!Users.get_by(phone: phone)
    json(conn, %{phone: exist?})
  end

  def search_user_by(conn, %{"email" => email}, _opts) do
    exist? = !!Users.get_by(email: email)
    json(conn, %{email: exist?})
  end

  def profiles_search(
        %{assigns: %{user_id: user_id}} = conn,
        %{"search" => %{"country_code" => country_code, "phone" => phone}},
        _opts
      ) do
    users = Users.search_by_phone(phone, %{for_id: user_id})

    render(conn, "profiles_search.json",
      search_term: %{"country_code" => country_code, "phone" => phone},
      fields: ["country_code_and_phone"],
      results: %{"country_code_and_phone" => users}
    )
  end

  def profiles_search(
        %{assigns: %{user_id: user_id}} = conn,
        %{"search" => phone, "fields" => ["phone"]},
        _opts
      ) do
    users = Users.search_by_phone(phone, %{for_id: user_id})

    render(conn, "profiles_search.json",
      search_term: phone,
      fields: ["phone"],
      results: %{"phone" => users}
    )
  end

  def profiles_search(
        %{assigns: %{user_id: user_id}} = conn,
        %{"search" => interest, "fields" => ["interests"]},
        _opts
      ) do
    users = Users.search_by_interest(interest, %{for_id: user_id})

    render(conn, "profiles_search.json",
      search_term: interest,
      fields: ["interest"],
      results: %{"interest" => users}
    )
  end

  def profiles_search(%{assigns: %{user_id: user_id}} = conn, %{"search" => phonenumbers}, _opts)
      when is_list(phonenumbers) do
    users = Users.search_by_phone_numbers(phonenumbers, %{for_id: user_id})

    render(conn, "profiles_search.json",
      search_term: phonenumbers,
      fields: ["phone"],
      results: %{"phone" => users}
    )
  end

  def profiles_search(%{assigns: %{user_id: user_id}} = conn, %{"search" => username}, _opts) do
    users_from_username_search = Users.search_by_username(username, %{for_id: user_id})
    users_from_first_name_search = Users.search_by_first_name(username, %{for_id: user_id})

    render(conn, "profiles_search.json",
      search_term: username,
      fields: ["username", "first_name"],
      results: %{
        "username" => users_from_username_search,
        "first_name" => users_from_first_name_search
      }
    )
  end

  def get_user_profile(%{assigns: %{user_id: user_id}} = conn, %{"user_name" => user_name}, _opts) do
    with %User{} = user <- BillBored.Users.get_user_profile(user_name, %{for_id: user_id}) do
      render(conn, "custom_user.json", user: user)
    else
      nil ->
        {:error, :not_found}

      error ->
        error
    end
  end

  def create(conn, params, _opts) do
    case Users.create(params) do
      {:ok, user} ->
        UserPoints.give_signup_points(user.id)
        if not is_nil(params["referee_code"]) do
          referee = Referrals.get_user_by_referral_code(params["referee_code"])
          UserPoints.give_referral_points(referee.id)
          Referrals.create(%{"referee_id" => referee.id, "referrer_id" => user.id})
        end
        # TODO job queue
        if user.email do
          BillBored.Users.send_email_verification(user)
        end

        # TODO job queue
        if user.phone && user.country_code do
          case service(PhoneVerification).start(%{
                 phone_number: %PhoneVerification.PhoneNumber{
                   country_code: user.country_code,
                   subscriber_number: user.phone
                 },
                 via: :sms
               }) do
            {:ok, %{message: message}} ->
              Logger.info(message)

            {:error, reason} ->
              raise("Failed to start phone verification:\n\n#{inspect(reason)}")
          end
        end

        render(conn, "full_user.json", user: BillBored.Helpers.replace_null(user))

      {:error, %{errors: [nickname: {"has already been taken", []}]}} ->
        conn
        |> put_status(400)
        |> json(%{username: ["A user with that username already exists."]})

      other ->
        other
    end
  end

  # TODO  remove
  def update(conn, %{"user_name" => username} = params, user_id) do
    user = Users.get_by(id: user_id)

    if username == user.username do
      update(conn, Map.delete(params, "user_name"), user_id)
    else
      send_resp(conn, 403, [])
    end
  end

  def update(conn, params, user_id) do
    user = Users.get_by(id: user_id)

    old_phone = user.phone
    old_email = user.email
    old_country_code = user.country_code

    case Users.update_user(user, params) do
      {:ok, user} ->
        # TODO verify email, phone number if they are updated
        if params["email"] && old_email != user.email do
          BillBored.Users.send_email_verification(user)
        end

        if params["phone"] || params["country_code"] do
          if old_phone != user.phone || old_country_code != user.country_code do
            case service(PhoneVerification).start(%{
                   phone_number: %PhoneVerification.PhoneNumber{
                     country_code: user.country_code,
                     subscriber_number: user.phone
                   },
                   via: :sms
                 }) do
              {:ok, %{message: message}} ->
                Logger.info(message)

              {:error, reason} ->
                raise("Failed to start phone verification:\n\n#{inspect(reason)}")
            end
          end
        end

        render(conn, "full_user.json", user: BillBored.Helpers.replace_null(user))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> json(%{
          success: false,
          errors: BillBored.Helpers.humanize_errors(changeset)
        })
    end
  end

  def delete_temporarily(conn, _params, user_id) do
    user = Users.get_by(id: user_id)

    Users.get_by(id: user_id)
    |> User.admin_changeset(%{deleted?: true})
    |> Repo.update()

    send_resp(conn, 204, [])
  end

  def index_friends_of_user(conn, %{"user_id" => user_id} = params, _opts) do
    users = BillBored.Users.index_friends(user_id, params)
    render(conn, "index.json", data: users)
  end

  def index_friends(conn, params, user_id) do
    params = Map.put(params, "user_id", user_id)
    index_friends_of_user(conn, params, user_id)
  end

  def get_all_users(
        %{assigns: %{user_id: user_id}} = conn,
        %{"last_seen_param" => last_seen_param, "direction_param" => direction_param},
        _opts
      ) do
    users =
      BillBored.Users.all_users_accounts(last_seen_param, direction_param, %{for_id: user_id})

    if length(users) == 0 do
      send_resp(
        conn,
        404,
        Jason.encode!(%{message: "No more users to be displayed!"}, pretty: true)
      )
    else
      render(conn, "list.json", users: users)
    end
  end

  def get_all_busisness_account(
        conn,
        %{"last_seen_param" => last_seen_param, "direction_param" => direction_param},
        _opts
      ) do
    users = BillBored.Users.all_business_accounts(last_seen_param, direction_param)

    if length(users) == 0 do
      send_resp(
        conn,
        404,
        Jason.encode!(%{message: "No more business account to be displayed!"}, pretty: true)
      )
    else
      render(conn, "list.json", users: users)
    end
  end

  def get_all_members_of_account(conn, %{"account_name" => account_name}, _opts) do
    members = BillBored.Users.get_member_of_busisness_account(account_name)

    if length(members) == 0 do
      send_resp(
        conn,
        404,
        Jason.encode!(
          %{message: "This business account does not have members yet!"},
          pretty: true
        )
      )
    else
      members = Enum.reject(members, &is_nil/1)
      render(conn, "members_of.json", members: members)
    end
  end

  def get_all_admins_of_account(conn, %{"account_name" => account_name}, _opts) do
    members = BillBored.Users.get_admin_of_busisness_account(account_name)

    if length(members) == 0 do
      send_resp(
        conn,
        404,
        Jason.encode!(
          %{message: "This business account does not have members yet!"},
          pretty: true
        )
      )
    else
      members = Enum.reject(members, &is_nil/1)
      render(conn, "members_of.json", members: members)
    end
  end

  def update_business_account(
        conn,
        %{
          "business_id" => business_id,
          "business_account_name" => business_account_name,
          "admin_user" => admin_user,
          "avatar" => avatar,
          "avatar_thumbnail" => avatar_thumbnail,
          "categories_to_add" => categories_to_add
        },
        _opts
      ) do
    response =
      BillBored.Users.update_business_account(
        String.to_integer(business_id),
        business_account_name,
        admin_user,
        avatar,
        avatar_thumbnail,
        categories_to_add
      )

    case response["status"] do
      201 ->
        render(conn, "business_account.json", user: response["account"])

      _ ->
        send_resp(
          conn,
          response["status"],
          Jason.encode!(%{message: response["message"]}, pretty: true)
        )
    end
  end

  def show_business_account(%{assigns: %{user_id: user_id}} = conn, %{"id" => business_account_id} = params, _opts) do
    with true <- BillBored.BusinessAccounts.Policy.authorize(:show, params, user_id),
         {:ok, business_account} <- BillBored.Users.get_business_account(id: business_account_id),
         business_account <- Repo.preload(business_account, [:business_category, :business_suggestion]),
         followers_count <- BillBored.Users.business_followers_count(business_account.id),
         business_account <- %BillBored.User{business_account | followers_count: followers_count} do
      render(conn, "business_account.json", user: business_account)
    else
      {false, :missing_business_membership = reason} ->
        Logger.debug("Access denied to show business account: #{inspect(reason)}")
        send_resp(conn, 403, [])

      error ->
        error
    end
  end

  def get_business_account_from_user(conn, %{"user_name" => user_name}, _opts) do
    user = BillBored.Users.get_by_username(user_name)

    unless user do
      send_resp(conn, 404, [])
    end

    render(conn, "business_accounts.json", users: user.business_accounts)
  end

  defp create_business_account_params(params) do
    result =
      [
        {"business_account_username", :username, true},
        {"business_account_name", :first_name, true},
        {"avatar", :avatar, true},
        {"avatar_thumbnail", :avatar_thumbnail, true},
        {"email", :email, true},
        {"location", :location, true},
        {"referral_code", :referral_code, false},
        {"admin_user", :admin_username, true},
        {"categories_to_add", :categories, true}
      ]
      |> Enum.reduce({[], %{}}, fn {src_key, dst_key, required}, {missing, found} ->
        case params do
          %{^src_key => value} ->
            {missing, Map.put(found, dst_key, value)}

          _ ->
            if required, do: {[src_key | missing], found}, else: {missing, found}
        end
      end)

    case result do
      {[], %{} = found} ->
        {:ok, found}

      {missing, _} ->
        {:error, :missing_required_params, Enum.map_join(missing, ", ", &to_string(&1))}
    end
  end

  defp parse_location([lat, long]), do: {:ok, %BillBored.Geo.Point{lat: lat, long: long}}
  defp parse_location(_), do: {:error, :invalid}

  def create_business_account(%{assigns: %{user_id: user_id}} = conn, params, _opts) do
    with {:ok, params} <- create_business_account_params(params),
         {%{
            admin_username: admin_username,
            categories: categories,
            location: location
          }, attrs} <- Map.split(params, [:admin_username, :categories, :location]),
         {:ok, location} <- parse_location(location),
         attrs <- Map.put(attrs, :user_real_location, location),
         owner_user <- Repo.get(User, user_id),
         {:ok, business_account} <- BillBored.Users.create_business_account(owner_user, admin_username, categories, attrs) do
      render(conn, "business_account.json", user: business_account)
    end
  end

  def add_members_to_business_account(conn, %{"members_to_add" => members_to_add}, _opts) do
    BillBored.Users.add_member_to_business_account(members_to_add)
    send_resp(conn, 200, Jason.encode!(%{message: "Users added to account"}, pretty: true))
  end

  def change_member_role_on_business_account(
        conn,
        %{
          "business_account_username" => business_account_username,
          "username" => username,
          "role" => role
        },
        _opts
      ) do
    BillBored.Users.change_member_role_on_business_account(
      business_account_username,
      username,
      role
    )

    send_resp(conn, :ok, [])
  end

  def remove_member_from_business_account(
        conn,
        %{"business_account_username" => business_account_username, "username" => username},
        _opts
      ) do
    BillBored.Users.remove_member_from_business_account(business_account_username, username)
    send_resp(conn, :ok, [])
  end

  def close_business_user_account(conn, %{"username" => username}, _opts) do
    BillBored.Users.close_business_user_account(username)
    send_resp(conn, :ok, [])
  end

  def close_business_account(conn, %{"business_account_name" => business_account_name}, _opts) do
    BillBored.Users.close_business_account(business_account_name)
    send_resp(conn, :ok, [])
  end

  def block_user(
        %Plug.Conn{assigns: %{user_id: user_id}} = conn,
        %{"blocked_user_id" => blocked_user_id},
        _opts
      ) do
    with %User{} = blocker <- Users.get_by_id(user_id),
         %User{} = blocked <- Users.get_by_id(blocked_user_id),
         {:ok, _block} <- UserBlocks.block(blocker, blocked) do
      send_resp(conn, :ok, [])
    else
      nil ->
        {:error, :not_found}

      error ->
        error
    end
  end

  def unblock_user(
        %Plug.Conn{assigns: %{user_id: user_id}} = conn,
        %{"blocked_user_id" => blocked_user_id},
        _opts
      ) do
    with %User{} = blocker <- Users.get_by_id(user_id),
         %User{} = blocked <- Users.get_by_id(blocked_user_id),
         :ok <- UserBlocks.unblock(blocker, blocked) do
      send_resp(conn, :ok, [])
    else
      nil ->
        {:error, :not_found}

      error ->
        error
    end
  end

  def get_blocked_users(%Plug.Conn{assigns: %{user_id: user_id}} = conn, _params, _opts) do
    with %User{} = blocker <- Users.get_by_id(user_id),
         blocked_users <- UserBlocks.get_blocked_by(blocker) do
      render(conn, "list.json", users: blocked_users)
    else
      nil ->
        {:error, :not_found}

      error ->
        error
    end
  end
end
