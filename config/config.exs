import Config

config :nostrum,
  token: System.get_env("BOT_TOKEN"),
  gateway_intents: [:guild_messages, :message_content],
  ffmpeg: nil
