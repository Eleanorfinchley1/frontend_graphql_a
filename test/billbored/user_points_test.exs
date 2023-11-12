defmodule BillBored.UserPointsTest do
  use BillBored.DataCase, async: true
  alias BillBored.UserPoints

  setup do
    %{user: insert(:user)}
  end

  test "Audit creation", %{user: user} do
    {:ok, audit} = UserPoints.create_audit(%{
        "user_id" => user.id,
        "points" => 10,
        "p_type" => "stream",
        "reason" => "signup"
      })
    assert audit.user_id == user.id
    assert audit.points == 10
    assert audit.p_type == "stream"
    assert audit.reason == "signup"
  end

  describe "Points created" do
    test "with first audit creation", %{user: user} do
      assert nil == UserPoints.get(user.id)
      {:ok, _} = UserPoints.create_audit(%{
          "user_id" => user.id,
          "points" => 10,
          "p_type" => "stream",
          "reason" => "signup"
        })
      assert nil != UserPoints.get(user.id)
    end
  end

  describe "Points increased or decreased" do
    test "by value of points in audit", %{user: user} do
      {:ok, _} = UserPoints.create_audit(%{
          "user_id" => user.id,
          "points" => 10,
          "p_type" => "stream",
          "reason" => "signup"
        })
      assert 10 == UserPoints.get(user.id).stream_points
      {:ok, _} = UserPoints.create_audit(%{
          "user_id" => user.id,
          "points" => -6,
          "p_type" => "stream",
          "reason" => "streaming"
        })
      assert 4 == UserPoints.get(user.id).stream_points
    end
  end

  describe "Audits creation failed" do
    test "with empty params", %{user: user} do
      {:error, %Ecto.Changeset{} = changeset} = UserPoints.create_audit(%{})
      assert errors_on(changeset) == %{
        user_id: ["can't be blank"],
        points: ["can't be blank"],
        p_type: ["can't be blank"],
        reason: ["can't be blank"]
      }
    end

    test "with invalid p_type or reason", %{user: user} do
      # invalid p_type
      {:error, %Ecto.Changeset{} = changeset} =
        UserPoints.create_audit(%{
          "user_id" => user.id,
          "points" => 10,
          "p_type" => "any",
          "reason" => "streaming"
        })
      assert errors_on(changeset) == %{
        p_type: ["is invalid"]
      }
      # invalid reason
      {:error, %Ecto.Changeset{} = changeset} =
        UserPoints.create_audit(%{
          "user_id" => user.id,
          "points" => 10,
          "p_type" => "stream",
          "reason" => "any"
        })
      assert errors_on(changeset) == %{
        reason: ["is invalid"]
      }
    end

    test "with negotive general points", %{user: user} do
      # total general points: 0
      {:error, %Ecto.Changeset{} = changeset} =
        UserPoints.create_audit(%{
          "user_id" => user.id,
          "points" => -10,
          "p_type" => "general",
          "reason" => "anticipation_double"
        })
      assert errors_on(changeset) == %{
        points: ["General point can't be negotive number"]
      }
      # total general points would be 10
      {:ok, _} = UserPoints.create_audit(%{
          "user_id" => user.id,
          "points" => 10,
          "p_type" => "general",
          "reason" => "anticipation_double"
        })
      {:error, %Ecto.Changeset{} = changeset} =
        UserPoints.create_audit(%{
          "user_id" => user.id,
          "points" => -5,
          "p_type" => "general",
          "reason" => "anticipation_double"
        })
      assert errors_on(changeset) == %{
        points: ["General point can't be negotive number"]
      }
    end

    test "if total stream points will be less than 0", %{user: user} do
      # total stream points: 0
      {:error, %Ecto.Changeset{} = changeset} =
        UserPoints.create_audit(%{
          "user_id" => user.id,
          "points" => -10,
          "p_type" => "stream",
          "reason" => "streaming"
        })
      assert errors_on(changeset) == %{
        stream_points: ["stream_points can't be less than 0"]
      }
      # total stream points would be 10
      {:ok, _} = UserPoints.create_audit(%{
          "user_id" => user.id,
          "points" => 10,
          "p_type" => "stream",
          "reason" => "signup"
        })
      # total stream points would be 4
      {:ok, _} = UserPoints.create_audit(%{
          "user_id" => user.id,
          "points" => -6,
          "p_type" => "stream",
          "reason" => "streaming"
        })
      assert 4 == UserPoints.get(user.id).stream_points
      {:error, %Ecto.Changeset{} = changeset} = UserPoints.create_audit(%{
          "user_id" => user.id,
          "points" => -6,
          "p_type" => "stream",
          "reason" => "streaming"
        })
      assert errors_on(changeset) == %{
        stream_points: ["stream_points can't be less than 0"]
      }
    end
  end
end
