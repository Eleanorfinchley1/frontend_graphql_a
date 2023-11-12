defmodule BillBored.InterestTest do
  use BillBored.DataCase, async: true
  alias BillBored.{Interest, Interests}

  describe "interests" do
    setup [:create_interests, :create_posts]

    test "get by id", %{interests: interests} do
      for interest <- interests do
        id = interest.id

        interest = Interests.get!(id)
        assert id == interest.id
        assert interest.popularity
      end
    end
  end

  describe "index" do
    setup do
      i1 = insert(:interest, hashtag: "one")
      i2 = insert(:interest, hashtag: "two")
      i3 = insert(:interest, hashtag: "three")
      pi1 = insert(:post_interest, interest: i1)
      pi2 = insert(:post_interest, interest: i2)
      pci1 = insert(:post_comment_interest, interest: i1)
      pci2 = insert(:post_comment_interest, interest: i3)

      {:ok,
       interests: [i1, i2, i3], post_interests: [pi1, pi2], post_comment_interests: [pci1, pci2]}
    end

    test "search", %{interests: [i1 | _]} do
      expected_hashtag = i1.hashtag

      assert %Scrivener.Page{entries: [%Interest{hashtag: ^expected_hashtag, popularity: 2}]} =
               Interests.index(%{"search" => i1.hashtag})
    end

    test "all", %{interests: [i1, i2, i3]} do
      expected_hashtag1 = i1.hashtag
      expected_hashtag2 = i2.hashtag
      expected_hashtag3 = i3.hashtag

      assert %Scrivener.Page{
               entries: [
                 %Interest{hashtag: ^expected_hashtag1, popularity: 2},
                 %Interest{hashtag: hashtag2, popularity: 1},
                 %Interest{hashtag: hashtag3, popularity: 1}
               ]
             } = Interests.index(%{})

      assert expected_hashtag2 in [hashtag2, hashtag3]
      assert expected_hashtag3 in [hashtag2, hashtag3]
    end
  end

  defp create_interests(_context) do
    interests =
      for _ <- 1..100 do
        insert(:interest)
      end

    {:ok, interests: interests}
  end

  defp create_posts(%{interests: interests} = _context) do
    posts =
      for _ <- 1..10 do
        post = insert(:post)

        for interest <- Enum.shuffle(interests) |> Enum.take(5) do
          insert(:post_interest, post: post, interest: interest)
        end

        post
      end

    {:ok, posts: posts}
  end
end
