defmodule BillBored.Post.CommentsTest do
  use BillBored.DataCase, async: true
  alias BillBored.Users
  alias BillBored.Post.{Comment, Comments}

  describe "get" do
    setup do
      post = insert(:post)
      comment = insert(:post_comment, post: post)
      %{comment: comment, post: post}
    end

    test "returns comment", %{comment: %Comment{id: comment_id}} do
      assert %Comment{id: ^comment_id} = Comments.get(comment_id)
    end

    test "does not return comment for blocked user", %{
      comment: %Comment{id: comment_id} = comment
    } do
      block = insert(:user_block, blocker: comment.author)
      assert is_nil(Comments.get(comment_id, for_id: block.blocked.id))
    end

    test "does not return comment of banned user", %{post: post} do
      comment = insert(:post_comment, post: post, author: insert(:user, banned?: true))
      assert is_nil(Comments.get(comment.id))
    end
  end

  describe "get!" do
    setup do
      post = insert(:post)
      comment = insert(:post_comment, post: post)
      %{comment: comment, post: post}
    end

    test "returns comment", %{comment: %Comment{id: comment_id}} do
      assert %Comment{id: ^comment_id} = Comments.get!(comment_id)
    end

    test "does not return comment for blocked user", %{
      comment: %Comment{id: comment_id} = comment
    } do
      block = insert(:user_block, blocker: comment.author)

      assert_raise Ecto.NoResultsError, fn ->
        Comments.get!(comment_id, for_id: block.blocked.id)
      end
    end

    test "does not return comment of banned user", %{post: post} do
      comment = insert(:post_comment, post: post, author: insert(:user, banned?: true))

      assert_raise Ecto.NoResultsError, fn ->
        Comments.get!(comment.id)
      end
    end
  end

  describe "load_children/1" do
    setup do
      post = insert(:post)
      parent_comment = insert(:post_comment, post: post)
      {:ok, comment: parent_comment, post: post}
    end

    test "without children", %{comment: comment} do
      assert [] == Comments.load_children(comment).children
    end

    test "with children", %{comment: comment, post: post} do
      %{id: c1_id} = c1 = insert(:post_comment, post: post, parent: comment)
      %{id: c2_id} = c2 = insert(:post_comment, post: post, parent: comment)
      %{id: c11_id} = _c11 = insert(:post_comment, post: post, parent: c1)
      %{id: c21_id} = c21 = insert(:post_comment, post: post, parent: c2)
      %{id: c12_id} = _c12 = insert(:post_comment, post: post, parent: c1)
      %{id: c211_id} = c211 = insert(:post_comment, post: post, parent: c21)
      %{id: c2111_id} = _c2111 = insert(:post_comment, post: post, parent: c211)

      assert [
               %Comment{
                 id: ^c2_id,
                 children: [
                   %Comment{
                     id: ^c21_id,
                     children: [
                       %Comment{
                         id: ^c211_id,
                         children: [
                           %Comment{
                             id: ^c2111_id,
                             children: []
                           }
                         ]
                       }
                     ]
                   }
                 ]
               },
               %Comment{
                 id: ^c1_id,
                 children: [
                   %Comment{id: ^c12_id, children: []},
                   %Comment{id: ^c11_id, children: []}
                 ]
               }
             ] = Comments.load_children(comment).children
    end

    test "with children for blocked user", %{comment: comment, post: post} do
      blocked_user = insert(:user)
      block1 = insert(:user_block, blocked: blocked_user)
      block2 = insert(:user_block, blocked: blocked_user)

      %{id: c1_id} =
        c1 =
        insert(:post_comment, post: post, parent: comment, author: blocked_user, body: "body1")

      %{id: c2_id} = c2 = insert(:post_comment, post: post, parent: comment)

      %{id: c11_id} =
        insert(:post_comment, post: post, parent: c1, author: block1.blocker, body: "text")

      %{id: c21_id} = c21 = insert(:post_comment, post: post, parent: c2)
      %{id: c12_id} = _c12 = insert(:post_comment, post: post, parent: c1)

      %{id: c211_id} =
        c211 =
        insert(:post_comment, post: post, parent: c21, author: block2.blocker, body: "smth")

      %{id: c2111_id} =
        insert(:post_comment, post: post, parent: c211, author: blocked_user, body: "body2111")

      assert [
               %Comment{
                 id: ^c2_id,
                 children: [
                   %Comment{
                     id: ^c21_id,
                     children: [
                       # Blocked comment with children is returned with empty body
                       %Comment{
                         id: ^c211_id,
                         body: "",
                         blocked?: true,
                         children: [
                           %Comment{
                             id: ^c2111_id,
                             body: "body2111",
                             children: []
                           }
                         ]
                       }
                     ]
                   }
                 ]
               },
               %Comment{
                 id: ^c1_id,
                 body: "body1",
                 children: [
                   %Comment{id: ^c12_id, children: []}
                   # SIC! Leaf blocked comment is not returned
                   # %Comment{id: ^c11_id, body: "", blocked?: true, children: []}
                 ]
               }
             ] = Comments.load_children(comment, for_id: blocked_user.id).children

      assert [
               %Comment{
                 id: ^c2_id,
                 children: [
                   %Comment{
                     id: ^c21_id,
                     children: [
                       %Comment{
                         id: ^c211_id,
                         body: "smth",
                         # Leaf comment of blocked user is not returned
                         children: []
                       }
                     ]
                   }
                 ]
               },
               %Comment{
                 id: ^c1_id,
                 # Comment of blocked user returned with hidden body
                 body: "",
                 blocked?: true,
                 children: [
                   %Comment{id: ^c12_id, children: []},
                   %Comment{id: ^c11_id, body: "text", children: []}
                 ]
               }
             ] = Comments.load_children(comment, for_id: block1.blocker.id).children
    end

    test "with children of banned users", %{comment: comment, post: post} do
      %{id: c1_id} =
        c1 =
        insert(:post_comment,
          post: post,
          parent: comment,
          body: "1",
          author: insert(:user, banned?: true)
        )

      %{id: c2_id} = c2 = insert(:post_comment, post: post, parent: comment, body: "2")
      %{id: c11_id} = _c11 = insert(:post_comment, post: post, parent: c1, body: "11")

      %{id: c21_id} =
        c21 =
        insert(:post_comment,
          post: post,
          parent: c2,
          body: "21",
          author: insert(:user, banned?: true)
        )

      %{id: c12_id} = _c12 = insert(:post_comment, post: post, parent: c1, body: "12")
      %{id: c211_id} = c211 = insert(:post_comment, post: post, parent: c21, body: "211")

      _c2111 =
        insert(:post_comment,
          post: post,
          parent: c211,
          body: "2111",
          author: insert(:user, banned?: true)
        )

      assert [
               %Comment{
                 id: ^c2_id,
                 children: [
                   %Comment{
                     id: ^c21_id,
                     # Comment of banned user returned with hidden body
                     body: "",
                     author: %{banned?: true},
                     blocked?: true,
                     children: [
                       %Comment{
                         id: ^c211_id,
                         # Leaf comment of banned user is not returned
                         children: []
                       }
                     ]
                   }
                 ]
               },
               %Comment{
                 id: ^c1_id,
                 # Comment of banned user returned with hidden body
                 body: "",
                 author: %{banned?: true},
                 blocked?: true,
                 children: [
                   %Comment{id: ^c12_id, body: "12", children: []},
                   %Comment{id: ^c11_id, body: "11", children: []}
                 ]
               }
             ] = Comments.load_children(comment).children

      block = insert(:user_block, blocked: c211.author)

      assert [
               %Comment{
                 id: ^c2_id,
                 # Comment subtree consisting of only blocked or banned users' comments is not returned
                 children: []
               },
               %Comment{
                 id: ^c1_id,
                 body: "",
                 author: %{banned?: true},
                 blocked?: true,
                 children: [
                   %Comment{id: ^c12_id, body: "12", children: []},
                   %Comment{id: ^c11_id, body: "11", children: []}
                 ]
               }
             ] = Comments.load_children(comment, %{for_id: block.blocker.id}).children
    end
  end

  describe "index_top/1" do
    setup do
      post = insert(:post)

      # shouldn't be returned, user is banned
      insert_list(2, :post_comment, post: post, author: insert(:user, banned?: true))

      {:ok, post: post}
    end

    test "returns top level comments for post", %{post: post} do
      %{id: c1_id} = c1 = insert(:post_comment, post: post)
      %{id: c2_id} = c2 = insert(:post_comment, post: post)
      _c11 = insert(:post_comment, post: post, parent: c1)
      c21 = insert(:post_comment, post: post, parent: c2)
      _c12 = insert(:post_comment, post: post, parent: c1)
      c211 = insert(:post_comment, post: post, parent: c21)
      _c2111 = insert(:post_comment, post: post, parent: c211)

      assert %Scrivener.Page{
               total_entries: 2,
               entries: [
                 %Comment{
                   id: ^c1_id,
                   children: nil
                 },
                 %Comment{
                   id: ^c2_id,
                   children: nil
                 }
               ]
             } = Comments.index_top(post.id, for_id: insert(:user).id)
    end

    test "does not return comments if user is blocked by author", %{post: post} do
      %{author_id: blocker_id} = c1 = insert(:post_comment, post: post)

      %{id: c2_id} = c2 = insert(:post_comment, post: post)
      _c11 = insert(:post_comment, post: post, parent: c1)
      c21 = insert(:post_comment, post: post, parent: c2)
      _c12 = insert(:post_comment, post: post, parent: c1)
      c211 = insert(:post_comment, post: post, parent: c21)
      _c2111 = insert(:post_comment, post: post, parent: c211)

      blocked_user = insert(:user)
      insert(:user_block, blocker: Users.get!(blocker_id), blocked: blocked_user)

      assert %Scrivener.Page{
               total_entries: 1,
               entries: [
                 %Comment{
                   id: ^c2_id,
                   children: nil
                 }
               ]
             } = Comments.index_top(post.id, for_id: blocked_user.id)
    end
  end

  describe "index_childs/1" do
    setup do
      post = insert(:post)
      comment = insert(:post_comment, post: post)

      # shouldn't be returned, user is banned
      insert_list(2, :post_comment,
        parent: comment,
        post: post,
        author: insert(:user, banned?: true)
      )

      {:ok, parent_comment: comment, post: post}
    end

    test "returns top level comments for post", %{post: post, parent_comment: parent_comment} do
      %{id: c1_id} = c1 = insert(:post_comment, post: post, parent: parent_comment)
      %{id: c2_id} = c2 = insert(:post_comment, post: post, parent: parent_comment)
      _c11 = insert(:post_comment, post: post, parent: c1)
      _c21 = insert(:post_comment, post: post, parent: c2)

      assert %Scrivener.Page{
               total_entries: 2,
               entries: [
                 %Comment{
                   id: ^c1_id,
                   children: nil
                 },
                 %Comment{
                   id: ^c2_id,
                   children: nil
                 }
               ]
             } = Comments.index_childs(parent_comment.id, for_id: insert(:user).id)
    end

    test "does not return comments if user is blocked by author", %{
      post: post,
      parent_comment: parent_comment
    } do
      %{author_id: blocker_id} = c1 = insert(:post_comment, post: post, parent: parent_comment)

      %{id: c2_id} = c2 = insert(:post_comment, post: post, parent: parent_comment)
      _c11 = insert(:post_comment, post: post, parent: c1)
      _c21 = insert(:post_comment, post: post, parent: c2)

      blocked_user = insert(:user)
      insert(:user_block, blocker: Users.get!(blocker_id), blocked: blocked_user)

      assert %Scrivener.Page{
               total_entries: 1,
               entries: [
                 %Comment{
                   id: ^c2_id,
                   children: nil
                 }
               ]
             } = Comments.index_childs(parent_comment.id, for_id: blocked_user.id)
    end
  end
end
