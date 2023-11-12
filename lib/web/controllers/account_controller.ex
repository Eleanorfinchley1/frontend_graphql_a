defmodule Web.AccountController do
  use Web, :controller
  require Logger

  alias BillBored.Users
  alias Users.PhoneVerification, as: PhoneVerificationModel

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  @otp_len 4
  def phone_verification(conn, %{"otp" => otp}, user_id) do
    # TODO this would be an empty string for a null otp
    otp = (is_binary(otp) && otp) || to_string(otp)
    # TODO why is the submitted otp padded?
    prefix = List.duplicate("0", @otp_len - String.length(otp)) |> Enum.join()
    otp = prefix <> otp

    user = Users.get_by_id(user_id)
    result = Users.verify(%PhoneVerificationModel{otp: otp}, user)

    case result do
      {:ok, _message} ->
        json(conn, %{verified: true})

      {:error, :duplicate_phone_number = reason} ->
        json(conn, %{verified: false, message: "This phone number is already taken", reason: reason})

      {:error, :internal_error = reason} ->
        json(conn, %{verified: false, message: "Internal error", reason: reason})

      {:error, message} ->
        user = Users.get(user_id)
        verified = user.verified_phone == user.phone
        json(conn, %{verified: verified, message: message})
    end
  end

  def phone_verification_resend(conn, _params, user_id) do
    user = Users.get_by_id(user_id)

    result =
      PhoneVerification.start(%{
        via: :sms,
        phone_number: %PhoneVerification.PhoneNumber{
          country_code: user.country_code,
          subscriber_number: user.phone
        }
      })

    case result do
      {:ok, msg} ->
        json(conn, msg)

      {:error, msg} ->
        raise("Failed to start phone verification:\n\n#{inspect(msg)}")
    end
  end

  def email_verification(conn, %{"token" => key, "email" => email}, _opts) do
    user = Users.get_by(email: email)

    result =
      case user.verified_email do
        "false" ->
          {:error, "No token was generated!"}

        ^key ->
          user
          |> Ecto.Changeset.change(verified_email: email)
          |> Repo.update()

          {:ok, "Email is confirmed!"}

        ^email ->
          {:ok, "Email is already confirmed!"}

        _other ->
          {:error, "Wrong token!"}
      end

    # TODO where is success field?
    case result do
      {:ok, message} -> json(conn, %{message: message})
      {:error, reason} -> json(conn, %{message: reason})
    end
  end

  def email_verification(conn, _no_token, _opts) do
    # If there is no token in our params, tell the user they've provided
    # an invalid token or expired token

    # TODO where is :success field?
    conn
    |> put_status(400)
    |> json(%{message: "Verification link is invalid!"})
  end

  def email_verification_resend(conn, _params, current_user_id) do
    user = BillBored.Users.get(current_user_id)
    BillBored.Users.send_email_verification(user)
    send_resp(conn, 204, [])
  end

  defp phone_number_hide(nil, _len), do: ""

  defp phone_number_hide(phone, len) do
    "…" <> String.slice(phone, -len..-1)
  end

  def password_reset(conn, %{"email" => email} = params, opts) when is_binary(email) do
    user = Users.get_by!(email: email)

    secret = Application.get_all_env(:billbored)[:otp_secret]

    # TODO we don't need authy to send totp, it's verified via authy of authenticator app
    otp = Totpex.generate_totp(secret)
    send_by_mail = Map.get(params, "by_email", true)

    msg = %{
      email: user.email,
      phone_number: phone_number_hide(user.phone, 3)
    }

    if user.phone && user.country_code && !send_by_mail do
      if unquote(Mix.env() == :test) do
        Users.create_change_password(%{
          hash: otp,
          user_id: user.id
        })

        json(conn, msg)
      else
        result =
          PhoneVerification.start(%{
            via: :sms,
            phone_number: %PhoneVerification.PhoneNumber{
              country_code: user.country_code,
              subscriber_number: user.phone
            },
            custom_code: otp
          })

        case result do
          {:ok, %{message: message}} ->
            Logger.info(message)

            Users.create_change_password(%{
              hash: otp,
              user_id: user.id
            })

            json(conn, msg)

          {:error, reason} ->
            Logger.error(
              "Failed to start phone verification:\n\n#{inspect(reason)}\n\n#{
                Exception.format_stacktrace()
              }"
            )

            password_reset(conn, Map.put(params, "by_email", true), opts)
        end
      end
    else
      {:ok, _} =
        Users.create_change_password(%{
          hash: otp,
          user_id: user.id
        })

      Mail.recover_password_in_email(user.email, %{
        username: user.username,
        host: Web.Endpoint.struct_url().host,
        otp: otp
      })

      json(conn, msg)
    end
  end

  def change_password(conn, %{"email" => _email, "password" => password, "otp" => otp}, _opts)
      when is_binary(otp) do
    with %{} = change_hash <- Users.get_change_password_by_hash(otp) do
      case change_hash.user_id
           |> Users.get_by_id()
           |> Users.update_user(%{password: password}) do
        {:ok, user} ->
          user.id
          |> Users.get_change_password_by_user()
          |> Enum.map(&Users.delete_change_password(&1))

          json(conn, %{success: true, message: "Password updated!"})

        {:error, changeset} ->
          {:error, changeset}
      end
    else
      _ ->
        conn
        |> put_status(422)
        # TODO everywhere we have :reason for failed requests, but this one has :message, why?
        |> json(%{success: false, message: "OTP is not valid!"})
    end
  end
end
