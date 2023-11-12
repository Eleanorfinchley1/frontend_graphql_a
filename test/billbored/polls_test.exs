defmodule BillBored.PollsTest do
  use BillBored.DataCase, async: true
  alias BillBored.Polls

  describe "polls" do
    test "get" do
      lovers = for _ <- 1..4, do: insert(:user)
      haters = for _ <- 1..6, do: insert(:user)
      neutral = insert(:user)

      for _ <- 1..5 do
        post = insert(:post)
        poll = insert(:poll, post: post)

        poll = Polls.get(poll.id, for: neutral)
        [yes, maybe, no] = poll.items

        refute yes.user_voted? || no.user_voted? || maybe.user_voted?
        assert yes.votes_count == 0
        assert no.votes_count == 0
        assert maybe.votes_count == 0

        #

        for pos <- lovers do
          insert(:poll_item_vote, poll_item: yes, user: pos)
        end

        insert(:poll_item_vote, poll_item: maybe, user: neutral)

        for neg <- haters do
          insert(:poll_item_vote, poll_item: no, user: neg)
        end

        for lover <- lovers do
          poll = Polls.get(poll.id, for: lover)
          [yes, maybe, no] = poll.items

          assert yes.user_voted?
          assert yes.votes_count == 4

          refute no.user_voted?
          assert no.votes_count == 6

          refute maybe.user_voted?
          assert maybe.votes_count == 1
        end

        for hater <- haters do
          poll = Polls.get(poll.id, for: hater)
          [yes, maybe, no] = poll.items

          refute yes.user_voted?
          assert yes.votes_count == 4

          assert no.user_voted?
          assert no.votes_count == 6

          refute maybe.user_voted?
          assert maybe.votes_count == 1
        end

        # neutral

        [yes, maybe, no] = Polls.get(poll.id, for: neutral).items

        assert maybe.user_voted?
        assert maybe.votes_count == 1

        refute yes.user_voted? || no.user_voted?
        assert yes.votes_count == 4
        assert no.votes_count == 6
      end
    end
  end
end
