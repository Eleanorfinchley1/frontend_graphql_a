defmodule Web.BusinessAccountView do
  use Web, :view
  alias BillBored.{User, Interest}

  if Mix.env() == :test do
    def render("user.json", %{
          user: %User{
            id: user_id,
            username: username,
            avatar: avatar,
            avatar_thumbnail: avatar_thumbnail,
            first_name: first_name,
            last_name: last_name
          }
        }) do
      %{
        "id" => user_id,
        "username" => username,
        "avatar" => avatar,
        "avatar_thumbnail" => avatar_thumbnail,
        "first_name" => first_name,
        "last_name" => last_name
      }
    end
  else
    def render("user.json", %{
          user: %User{
            id: user_id,
            username: username,
            avatar: avatar,
            avatar_thumbnail: avatar_thumbnail,
            first_name: first_name,
            last_name: last_name
          }
        }) do
      # after ten minutes
      expires_at = :os.system_time(:seconds) + 10 * 60 * 60

      signed_avatar =
        if avatar do
          Signer.create_signed_url(
            "GET",
            expires_at,
            "/#{System.get_env("GS_MEDIA_BUCKET_NAME")}/#{avatar}"
          )
        end

      signed_avatar_thumbnail =
        if avatar_thumbnail do
          Signer.create_signed_url(
            "GET",
            expires_at,
            "/#{System.get_env("GS_MEDIA_BUCKET_NAME")}/#{avatar_thumbnail}"
          )
        end

      %{
        "id" => user_id,
        "username" => username,
        "avatar" => signed_avatar,
        "avatar_thumbnail" => signed_avatar_thumbnail,
        "first_name" => first_name,
        "last_name" => last_name
      }
    end
  end

  def render("custom_user.json", %{
        user: %User{
          id: user_id,
          username: username,
          avatar: avatar,
          avatar_thumbnail: avatar_thumbnail,
          first_name: first_name,
          last_name: last_name,
          interests_interest: interests_interest,
          referral_code: referral_code
        }
      }) do
    case interests_interest do
      %Interest{} ->
        Web.InterestView.render("custom_interests.json", %{interests_interest: interests_interest})

      _other ->
        nil
    end

    # after ten minutes
    expires_at = :os.system_time(:seconds) + 10 * 60 * 60

    signed_avatar =
      if avatar do
        Signer.create_signed_url(
          "GET",
          expires_at,
          "/#{System.get_env("GS_MEDIA_BUCKET_NAME")}/#{avatar}"
        )
      end

    signed_avatar_thumbnail =
      if avatar_thumbnail do
        Signer.create_signed_url(
          "GET",
          expires_at,
          "/#{System.get_env("GS_MEDIA_BUCKET_NAME")}/#{avatar_thumbnail}"
        )
      end

    %{
      "id" => user_id,
      "username" => username,
      "avatar" => signed_avatar,
      "avatar_thumbnail" => signed_avatar_thumbnail,
      "first_name" => first_name,
      "last_name" => last_name,
      "referral_code" => referral_code,
      "user_tags" => interests_interest
    }
  end

  def render("friends.json", %{users: users}) do
    Enum.map(users, fn %User{} = user ->
      render("user.json", %{user: user})
    end)
  end
end
