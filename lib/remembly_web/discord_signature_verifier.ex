defmodule DiscordSignatureVerifier do
  def valid_request?(expected_signature, timestamp, body, key) do
    payload = "#{timestamp}#{body}"

    case Ed25519.valid_signature?(from_hex(expected_signature), payload, from_hex(key)) do
      true -> :ok
      false -> {:error, "Signatures do not match"}
    end
  end

  def from_hex(<<>>), do: ""

  def from_hex(s) do
    size = div(byte_size(s), 2)
    {n, ""} = s |> Integer.parse(16)
    zero_pad(:binary.encode_unsigned(n), size)
  end

  def zero_pad(s, size) when byte_size(s) == size, do: s
  def zero_pad(s, size) when byte_size(s) < size, do: zero_pad(<<0>> <> s, size)
end
