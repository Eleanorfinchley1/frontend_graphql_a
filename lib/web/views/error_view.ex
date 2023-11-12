defmodule Web.ErrorView do
  use Web, :view

  def render("changeset.json", %{changeset: %Ecto.Changeset{} = changeset}) do
    %{"success" => false, "reason" => BillBored.Helpers.humanize_errors(changeset)}
  end

  def render("multi_changeset.json", %{changeset: %Ecto.Changeset{} = changeset}) do
    %{"success" => false, "reason" => BillBored.Helpers.humanize_errors(changeset)}
  end

  def render("unprocessable.json", %{reason: reason} = params) do
    human_reason = if is_binary(reason) or is_atom(reason) do
      Gettext.dgettext(Web.Gettext, "errors", reason |> to_string(), params)
    else
      dgettext("errors", "An error occured", params)
    end

    %{"success" => false, "error" => reason, "reason" => human_reason}
  end

  def render("404.html", _assigns) do
    "Page not found"
  end

  def render("500.html", _assigns) do
    "Internal server error"
  end

  def render("404.json", _assigns) do
    %{"error" => "Page not found"}
  end

  def render("500.json", _assigns) do
    %{"error" => "Internal server error"}
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(template, assigns) do
    render("500#{Path.extname(template)}", assigns)
  end
end
