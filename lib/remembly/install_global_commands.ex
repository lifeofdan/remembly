defmodule Remembly.InstallGlobalCommands do
  import Logger

  def register_commands do
    debug("We register our commands...")
    base_url = "https://discord.com/api/v10"
    app_id = System.get_env("DISCORD_APP_ID")
    discord_token = System.get_env("DISCORD_TOKEN")
    body = Jason.encode!(Remembly.Commands.all_commands_list())

    HTTPoison.put("#{base_url}/applications/#{app_id}/commands", body,
      "Content-Type": "application/json; charset=UTF-8",
      Authorization: "Bot #{discord_token}"
    )
  end
end
