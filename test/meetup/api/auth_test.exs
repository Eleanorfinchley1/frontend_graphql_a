defmodule Meetup.API.AuthTest do
  use BillBored.DataCase, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    HTTPoison.start()
  end

  test "get_authorize/1" do
    ExVCR.Config.filter_url_params(false)

    use_cassette "meetup_auth_authorize" do
      assert {:ok, %{"code" => "798d0c47690dbad8e774e93fca14e805"}} =
               Meetup.API.Auth.get_authorize()
    end
  end

  describe "without saved token" do
    setup do
      :ets.delete(Meetup.API.Auth, :auth_info)
      ExVCR.Config.filter_url_params(true)

      :ok
    end

    test "get_access/1" do
      use_cassette "meetup_auth_access_token" do
        assert {:ok,
        %{
          "access_token" => "4986c3b2ef02ed643f637064003399e7",
          "expires_in" => 3600,
          "member" => %{
            "city" => "Moscow",
            "country" => "ru",
            "id" => 301877668,
            "lat" => 55.75222,
            "lon" => 37.615558,
            "name" => "prereg_member_8254347036754253",
            "state" => "71"
          },
          "refresh_token" => "54689324b5fd001aff9d9a0a60360ae6",
          "token_type" => "bearer"
        }} = Meetup.API.Auth.get_access("798d0c47690dbad8e774e93fca14e805")
      end
    end

    test "get_access_token/1" do
      use_cassette "meetup_auth_access_token" do
        assert {:ok, "4986c3b2ef02ed643f637064003399e7"} = Meetup.API.Auth.get_access_token()
      end
    end
  end

  describe "with saved token" do
    setup do
      :ets.insert(
        Meetup.API.Auth,
        {:auth_info, %{"access_token" => "95d6541de027178705942b1f27981494"}}
      )

      :ok
    end

    test "get_access_token/1" do
      assert {:ok, "95d6541de027178705942b1f27981494"} = Meetup.API.Auth.get_access_token()
    end
  end
end
