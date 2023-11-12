defmodule FakeSearchable do
  @moduledoc "To be used to create fake data for text search benchmark"

  alias BillBored.{User}

  @usernames [
    "TestThree",
    "testing123",
    "d7uQyogSZC",
    "TestOne",
    "@arshdeep",
    "new105",
    "new106",
    "new107",
    "testing03",
    "1fqLNvFCYG",
    "test11",
    "test10",
    "@qwerty1390",
    "new104",
    "new103",
    "@first",
    "@arshdeepk",
    "Zgd9r8cEla",
    "AdminTestOne",
    "AdminTestThree",
    "AdminTestTwo",
    "arsh",
    "arsh1390",
    "@arshdeep.trantor",
    "helli",
    "hello",
    "hello123",
    "LT30xRTKHU",
    "new101",
    "qwerty",
    "testing101",
    "test1003",
    "tarsh",
    "test01",
    "test02",
    "test03",
    "test04",
    "test05",
    "test07",
    "test09",
    "zHBiw7ImsM",
    "test1001",
    "nimishtest",
    "test1005",
    "test1007",
    "@k_hiphistos",
    "chirag123",
    "test1006",
    "testing05",
    "TestTwo",
    "testing02",
    "chigs123",
    "rXcysXWgVh",
    "4KgtCxIvqy",
    "ahIcv1BaTo",
    "5CMvdn59iw",
    "harjot",
    "helloworld",
    "testing11",
    "testfake",
    "test1002",
    "test1004",
    "test08",
    "nimish123",
    "reepa.dhiman",
    "shikha",
    "test1008",
    "shikhasingla",
    "@samwelopiyo",
    "testing04",
    "mxIqfINquW",
    "testing07",
    "testing06",
    "testing08",
    "chemwiz",
    "SamwelOpiyo",
    "erwinr",
    "linichagas",
    "winnieomoye95",
    "TRSjzQGOPL",
    "owdrmKSw3J",
    "OXNxJNDdDG",
    "KALGeJSIeE",
    "k0l1piwhJ2",
    "aNobRCo7hO",
    "h6OoHjOMpM",
    "theman"
  ]

  @spec insert_users :: [user_ids :: pos_integer]
  def insert_users do
    @usernames
    |> Enum.map(fn username ->
      image_url = Faker.Avatar.image_url()

      phone =
        case Faker.Phone.EnUs.phone() do
          # ** (Postgrex.Error) ERROR 22001 (string_data_right_truncation):
          #    value too long for type character varying(12)
          <<fake_phone::12-bytes, _::bytes>> ->
            fake_phone

          fake_phone ->
            fake_phone
        end

      %{
        password: Faker.String.base64(10),
        is_superuser: false,
        username: username,
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: Faker.Internet.email(),
        is_staff: false,
        is_active: true,
        date_joined: DateTime.utc_now(),
        avatar: image_url,
        bio: Faker.Lorem.sentence(10),
        sex: "m",
        birthdate: Faker.Date.date_of_birth(),
        prefered_radius: 1,
        enable_push_notifications: false,
        avatar_thumbnail: image_url,
        country_code: Faker.Address.country_code(),
        phone: phone,
        area: Faker.Address.city()
      }
    end)
    |> Enum.chunk_every(1000)
    |> Enum.reduce([], fn chunk, acc_user_ids ->
      {_inserted_count, users} = Repo.insert_all(User, chunk, returning: [:id])
      Enum.map(users, fn %User{id: user_id} -> user_id end) ++ acc_user_ids
    end)
  end

  def setup do
    IO.puts("-- creating users")
    insert_users()
  end

  def cleanup do
    Repo.truncate(User)
  end
end

FakeSearchable.cleanup()
FakeSearchable.setup()
