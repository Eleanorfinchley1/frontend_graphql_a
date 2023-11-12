defmodule Web.BusinessOfferView do
  use Web, :view

  def render("show.json", %{business_offer: business_offer}) do
    Map.take(business_offer, [
      :discount,
      :discount_code,
      :business_address,
      :qr_code,
      :bar_code,
      :expires_at
    ])
  end
end
