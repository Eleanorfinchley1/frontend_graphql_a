defmodule BillBored.Feedbacks do
  @moduledoc ""

  use BillBored, :schema
  use Scrivener
  alias BillBored.Feedback

  def create_or_update_feedback(id, attrs) do
    Feedback
    |> Repo.get(id)
    |> case do
      %Feedback{} = user -> update_feedback(user, attrs)
      _ -> create_feedback(attrs)
    end
  end

  def create_feedback(attrs \\ %{}) do
    %Feedback{}
    |> Feedback.changeset(attrs)
    |> Repo.insert()
  end

  def update_feedback(%Feedback{} = feedback, attrs \\ %{}) do
    feedback
    |> Feedback.changeset(attrs)
    |> Repo.update()
  end

  def delete_feedback(%Feedback{} = feedback) do
    Repo.delete(feedback)
  end
end
