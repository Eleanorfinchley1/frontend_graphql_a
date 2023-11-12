defmodule BillBored.Geo.Hash do
  use Bitwise, only_operators: true
  alias BillBored.Geo.Point

  @min_precision 1
  @max_precision 12
  @precision_dims [
    {12, 0.037, 0.019},
    {11, 0.149, 0.149},
    {10, 1.2, 0.595},
    {9, 4.8, 4.8},
    {8, 38.2, 19.0},
    {7, 152.9, 152.4},
    {6, 1_200, 609.4},
    {5, 4_900, 4_900},
    {4, 39_100, 19_500},
    {3, 156_500, 156_000},
    {2, 1_252_3000, 624_100},
    {1, 5_009_400, 4_992_600}
  ]

  @earth_radius_m 6_371_008.8

  def all_within_safe(%Point{} = point, radius, precision) do
    max_safe_precision = min(@max_precision, estimate_precision_at(point, 2 * radius) + 2)

    if precision > max_safe_precision do
      {:error, :unsafe_precision}
    else
      {:ok, all_within(point, radius, precision)}
    end
  end

  def all_within(location, radius, precision) do
    boxes_within(location, radius)
    |> Enum.flat_map(fn box -> Geobox.encode_geohashes(box, precision) end)
  end

  defp boxes_within(%Point{long: lon, lat: lat}, radius) do
    distance_rad = radius / @earth_radius_m
    max_y = lat + rad_to_deg(distance_rad)
    min_y = lat - rad_to_deg(distance_rad)
    max_x = lon + rad_to_deg(distance_rad / :math.cos(deg_to_rad(lat)))
    min_x = lon - rad_to_deg(distance_rad / :math.cos(deg_to_rad(lat)))

    cond do
      abs(min_x) + abs(max_x) > 360.0 ->
        [
          clamp_bbox([180.0, max_y, -180, min_y])
        ]

      min_x < -180.0 ->
        [
          clamp_bbox([max_x, max_y, -180.0, min_y]),
          clamp_bbox([180.0, max_y, 360.0 + min_x, min_y])
        ]

      max_x > 180 ->
        [
          clamp_bbox([180.0, max_y, min_x, min_y]),
          clamp_bbox([-360.0 + max_x, max_y, -180.0, min_y])
        ]

      true ->
        [
          clamp_bbox([max_x, max_y, min_x, min_y])
        ]
    end
  end

  defp clamp_bbox([max_x, max_y, min_x, min_y]) do
    max_y = if max_y > 90, do: 90, else: max_y
    min_y = if min_y < -90, do: -90, else: min_y
    max_x = if max_x > 180, do: 180, else: max_x
    min_x = if min_x < -180, do: 180, else: min_x

    [max_x, max_y, min_x, min_y]
  end

  defp deg_to_rad(deg) do
    deg * (:math.pi() / 180.0)
  end

  defp rad_to_deg(rad) do
    rad * (180.0 / :math.pi())
  end

  def estimate_precision_at(%Point{}, radius) do
    case Enum.find(@precision_dims, fn {_, _, dim} -> radius < dim end) do
      nil -> @min_precision
      {precision, _, _} -> precision
    end
  end

  def int_to_geobase32(inthash, precision \\ @max_precision) do
    bits = :binary.encode_unsigned(inthash)
    hash_bits = precision * 5
    extra_bits = bit_size(bits) - hash_bits
    <<_extra::size(extra_bits),bits::bitstring>> = bits
    Geohash.to_geobase32(bits)
  end

  def from_integer(inthash, precision \\ @max_precision) do
    bits = :binary.encode_unsigned(inthash)
    hash_bits = precision * 5
    extra_bits = bit_size(bits) - hash_bits
    <<_extra::size(extra_bits),bits::bitstring>> = bits
    Geohash.bits_to_coordinates_pair(bits)
  end

  def to_integer(geohash, target_precision \\ @max_precision) do
    bithash = Geohash.decode_to_bits(geohash)
    hash_bits = bit_size(bithash)
    <<num::size(hash_bits)-unsigned-integer>> = bithash

    case 5 * target_precision - hash_bits do
      0 -> num
      rest_bits when rest_bits > 0 -> num <<< rest_bits
    end
  end

  def to_integer_range(geohash, target_precision) do
    bithash = Geohash.decode_to_bits(geohash)
    do_integer_range(bithash, target_precision)
  end

  def to_integer_range(geohash, hash_precision, target_precision) do
    bithash = Geohash.decode_to_bits(String.slice(geohash, 0..(hash_precision - 1)))
    do_integer_range(bithash, target_precision)
  end

  defp do_integer_range(bithash, target_precision) do
    hash_bits = bit_size(bithash)
    <<left::size(hash_bits)-unsigned-integer>> = bithash

    case 5 * target_precision - hash_bits do
      0 ->
        {left, left}

      rest_bits when rest_bits > 0 ->
        left = left <<< rest_bits
        right = left ||| (1 <<< rest_bits) - 1
        {left, right}
    end
  end
end
