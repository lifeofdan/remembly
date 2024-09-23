defmodule DiscordSignatureVerifierTest do
  use ExUnit.Case

  test "valid_request? with valid signature" do
    expected_signature =
      "f31a129c4e06d93e195ea019392fc568fa7d63c9b43beb436d75f6826d5e5d36270763ee438f13ad5686ed310e8fa3253426af798927bf69cee2ff21be589109"

    timestamp = "1625603592"
    body = "this should be a json."
    key = "e421dceefff3a9d008b7898fcc0974813201800419d72f36d51e010d6a0acb71"

    assert {:ok, _} =
             DiscordSignatureVerifier.valid_request?(expected_signature, timestamp, body, key)
  end
end
