defmodule BillBored.LivestreamsTest do
  use BillBored.DataCase, async: true
  alias BillBored.{Livestream, Livestreams}

  describe "create" do
    test "with valid params" do
      user = insert(:user)

      params = %{
        "title" => "some livestream",
        "location" => %{
          "coordinates" => [40.5, -50.0],
          "type" => "Point"
        }
      }

      {:ok, %Livestream{} = livestream} = Livestreams.create(params, owner_id: user.id)

      assert livestream.owner_id == user.id
      assert livestream.title == "some livestream"
      assert livestream.location == %BillBored.Geo.Point{lat: 40.5, long: -50.0}
    end

    test "with empty params" do
      user = insert(:user)
      empty_params = %{}

      {:error, %Ecto.Changeset{} = changeset} =
        Livestreams.create(empty_params, owner_id: user.id)

      assert errors_on(changeset) == %{
               title: ["can't be blank"],
               location: ["can't be blank"]
             }
    end

    test "with invalid owner foreign key" do
      {:error, %Ecto.Changeset{} = changeset} = Livestreams.create(%{}, owner_id: nil)

      assert errors_on(changeset) == %{
               title: ["can't be blank"],
               location: ["can't be blank"],
               owner_id: ["can't be blank"]
             }
    end
  end

  describe "create comment" do
    test "with valid params" do
      livestream = insert(:livestream)
      author = insert(:user)

      params = %{
        "body" => "some comment"
      }

      {:ok, %Livestream.Comment{} = comment} =
        Livestreams.create_comment(params, livestream_id: livestream.id, author_id: author.id)

      assert comment.author_id == author.id
      assert comment.livestream_id == livestream.id
      assert comment.body == "some comment"
    end

    test "with empty params" do
      livestream = insert(:livestream)
      author = insert(:user)

      empty_params = %{}

      {:error, %Ecto.Changeset{} = changeset} =
        Livestreams.create_comment(
          empty_params,
          livestream_id: livestream.id,
          author_id: author.id
        )

      assert errors_on(changeset) == %{
               body: ["can't be blank"]
             }
    end

    test "with invalid foreign keys" do
      empty_params = %{}

      {:error, %Ecto.Changeset{} = changeset} =
        Livestreams.create_comment(
          empty_params,
          livestream_id: nil,
          author_id: nil
        )

      assert errors_on(changeset) == %{
               body: ["can't be blank"],
               author_id: ["can't be blank"],
               livestream_id: ["can't be blank"]
             }
    end
  end

  describe "create upvote" do
    test "with valid params" do
      livestream = insert(:livestream)
      user = insert(:user)

      assert :ok == Livestreams.create_or_update_vote(user.id, livestream.id, "upvote")

      assert Repo.get_by!(Livestream.Vote, user_id: user.id, livestream_id: livestream.id).vote_type ==
               "upvote"

      assert :ok == Livestreams.create_or_update_vote(user.id, livestream.id, "")

      refute Repo.get_by(Livestream.Vote, user_id: user.id, livestream_id: livestream.id)
    end
  end

  describe "create comment upvote" do
    test "with valid params" do
      livestream = insert(:livestream)
      user = insert(:user)
      comment = insert(:livestream_comment, livestream: livestream)

      assert :ok == Livestreams.create_or_update_comment_vote(user.id, comment.id, "upvote")

      assert Repo.get_by!(Livestream.Comment.Vote, comment_id: comment.id, user_id: user.id).vote_type ==
               "upvote"

      assert :ok == Livestreams.create_or_update_comment_vote(user.id, comment.id, "")

      refute Repo.get_by(Livestream.Comment.Vote, comment_id: comment.id, user_id: user.id)
    end
  end

  describe "search" do
    setup :create_livestreams

    # TODO refactor (sma e as posts, can dry)

    test "by point", %{livestreams: [l1, l2]} do
      [%Livestream{} = found_l1, %Livestream{} = found_l2] =
        Livestreams.list_by_location(%BillBored.Geo.Point{lat: 40.5, long: -50.0}, %{
          radius_in_m: 10000
        })

      assert found_l1.id == l1.id
      assert found_l2.id == l2.id
    end

    test "by point for blocked user", %{livestreams: [%{id: l1_id} = l1, %{id: l2_id} = l2]} do
      block1 = insert(:user_block, blocker: l1.owner)
      block2 = insert(:user_block, blocked: l2.owner)

      [%Livestream{id: ^l2_id}] =
        Livestreams.list_by_location(%BillBored.Geo.Point{lat: 40.5, long: -50.0}, %{
          radius_in_m: 10000,
          for: block1.blocked
        })

      [%Livestream{id: ^l1_id}] =
        Livestreams.list_by_location(%BillBored.Geo.Point{lat: 40.5, long: -50.0}, %{
          radius_in_m: 10000,
          for: block2.blocker
        })
    end

    test "within polygon", %{livestreams: [l1, l2]} do
      [%Livestream{} = found_l1, %Livestream{} = found_l2] =
        Livestreams.list_by_location(%BillBored.Geo.Polygon{
          coords: [
            %BillBored.Geo.Point{lat: 40.0, long: -49.0},
            %BillBored.Geo.Point{lat: 40.0, long: -55.0},
            %BillBored.Geo.Point{lat: 50.7, long: -55.0},
            %BillBored.Geo.Point{lat: 50.7, long: -49.0},
            %BillBored.Geo.Point{lat: 40.0, long: -49.0}
          ]
        })

      assert found_l1.id == l1.id
      assert found_l2.id == l2.id
    end

    test "within polygon for blocked user", %{livestreams: [%{id: l1_id} = l1, %{id: l2_id} = l2]} do
      block1 = insert(:user_block, blocker: l2.owner)
      block2 = insert(:user_block, blocked: l1.owner)

      [%Livestream{id: ^l1_id}] =
        Livestreams.list_by_location(
          %BillBored.Geo.Polygon{
            coords: [
              %BillBored.Geo.Point{lat: 40.0, long: -49.0},
              %BillBored.Geo.Point{lat: 40.0, long: -55.0},
              %BillBored.Geo.Point{lat: 50.7, long: -55.0},
              %BillBored.Geo.Point{lat: 50.7, long: -49.0},
              %BillBored.Geo.Point{lat: 40.0, long: -49.0}
            ]
          },
          %{for: block1.blocked}
        )

      [%Livestream{id: ^l2_id}] =
        Livestreams.list_by_location(
          %BillBored.Geo.Polygon{
            coords: [
              %BillBored.Geo.Point{lat: 40.0, long: -49.0},
              %BillBored.Geo.Point{lat: 40.0, long: -55.0},
              %BillBored.Geo.Point{lat: 50.7, long: -55.0},
              %BillBored.Geo.Point{lat: 50.7, long: -49.0},
              %BillBored.Geo.Point{lat: 40.0, long: -49.0}
            ]
          },
          %{for: block2.blocker}
        )
    end
  end

  defp create_livestreams(_context) do
    %Livestream{} =
      l1 =
      insert(
        :livestream,
        location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
        active?: true
      )

    %Livestream{} =
      l2 =
      insert(
        :livestream,
        location: %BillBored.Geo.Point{lat: 40.51, long: -50.0},
        active?: true
      )

    # shouldn't be found (too far)
    %Livestream{} =
      _l3 = insert(:livestream, location: %BillBored.Geo.Point{lat: 0, long: 0}, active?: true)

    # shouldn't be found (not active)
    %Livestream{} =
      _l4 =
      insert(:livestream,
        location: %BillBored.Geo.Point{lat: 0, long: 0},
        active?: false
      )

    # shouldn't be found (owner banned)
    %Livestream{} =
      _l5 =
      insert(:livestream,
        location: %BillBored.Geo.Point{lat: 40.51, long: -50.0},
        active?: true,
        owner: insert(:user, banned?: true)
      )

    # shouldn't be found (not within 24h time frame)
    %Livestream{} =
      _l6 =
      insert(
        :livestream,
        location: %BillBored.Geo.Point{lat: 40.51, long: -50.0},
        created: into_past(DateTime.utc_now(), 30),
        active?: true
      )

    {:ok, livestreams: [l1, l2]}
  end

  @spec into_past(DateTime.t(), pos_integer) :: DateTime.t()
  defp into_past(dt, hours) do
    DateTime.from_unix!(DateTime.to_unix(dt) - hours * 60 * 60)
  end
end
