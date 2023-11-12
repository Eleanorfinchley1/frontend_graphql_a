defmodule Mail do
  @moduledoc """
  This module implements the fintion for sending mail.
  """
  use Bamboo.Phoenix, view: Web.EmailView
  import Bamboo.Email
  alias Mail.Mailer

  @doc """
  This function sends template: `"sign_in.html.eex"`.
  """
  @spec sign_in_email(struct) :: Bamboo.Email.t()
  def sign_in_email(person) do
    base_email()
    |> to("#{person.email}")
    |> subject("Welcome to Dropchats!")
    |> html_body("<strong>Welcome</strong>")
    |> assign(:person, person)
    |> render("sign_in.html")
    |> Mailer.deliver_now()
  end

  @doc """
  This function sends template: `"recover_password.html.eex"`.
  """
  @spec recover_password_in_email(String.t(), struct) :: Bamboo.Email.t()
  def recover_password_in_email(email, data) do
    base_email()
    |> to("#{email}")
    |> subject("Welcome to Dropchats!")
    |> html_body("<strong>Dropchats recovery password</strong>")
    |> assign(:data, data)
    |> render("recover_password.html")
    |> Mailer.deliver_now()
  end

  @doc """
  This function sends template: `"invite.html.eex"`.
  """
  @spec send_invite(String.t(), struct) :: Bamboo.Email.t()
  def send_invite(email, data) do
    base_email()
    |> to("#{email}")
    |> subject("Invitation To Join Dropchats")
    |> html_body("<strong>Dropchats invitation</strong>")
    |> assign(:data, data)
    |> render("invite.html")
    |> Mailer.deliver_now()
  end

  @doc """
  This function sends template: `"email_verification.html.eex"`.
  """
  @spec email_verification(String.t(), map) :: Bamboo.Email.t()
  def email_verification(email, data) do
    base_email()
    |> to("#{email}")
    |> subject("Welcome to Dropchats!")
    |> assign(:data, data)
    |> render("email_verification.html")
    |> Mailer.deliver_later()
  end

  @doc """
  This function sends template: `"email_invitation.html.eex"`.
  """
  @spec email_invitation(String.t(), map) :: Bamboo.Email.t()
  def email_invitation(email, data) do
    base_email()
    |> to("#{email}")
    |> subject("Invited to Dropchats Admin Page!")
    |> assign(:data, data)
    |> render("email_invitation.html")
    |> Mailer.deliver_later()
  end

  @doc """
  This function sends template: `"email_reset_account.html.eex"`.
  """
  @spec email_reset_account(String.t(), map) :: Bamboo.Email.t()
  def email_reset_account(email, data) do
    base_email()
    |> to("#{email}")
    |> subject("Login to Dropchats Admin Page!")
    |> assign(:data, data)
    |> render("email_reset_account.html")
    |> Mailer.deliver_later()
  end

  defp base_email do
    new_email()
    |> from({"Dropchats", "noreply@dropchats.one"})
    |> put_header("Reply-To", "noreply@dropchats.one")
  end
end
