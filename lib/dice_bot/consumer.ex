defmodule DiceBot.Consumer do
  use Nostrum.Consumer
  alias Nostrum.Api.Message

  @valid_dice [4, 6, 8, 10, 12, 20]
  @valid_dice_str @valid_dice |> Enum.map(&to_string/1) |> Enum.join(", ")

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    if msg.author.bot do
      :ignore
    else
      handle_message(msg)
    end
  end

  # Ignore any other events
  def handle_event(_), do: :ok

  defp handle_message(msg) do
    case msg.content do
      "!ping" ->
        {:ok, _message} = Message.create(msg.channel_id, "pong")

      "!roll" ->
        {:ok, _message} =
          Message.create(
            msg.channel_id,
            "Uso: `!roll <facce> <lanci>` - Dadi consentiti: #{@valid_dice_str}"
          )

      "!roll" <> params ->
        case(String.split(params, " ", trim: true)) do
          [dice_type] ->
            handle_roll(msg, dice_type, "1")

          [dice_type, rolls] ->
            handle_roll(msg, dice_type, rolls)

          _ ->
            Message.create(
              msg.channel_id,
              "Formato non valido. Uso: `!roll <facce> <lanci>` - Dadi consentiti: #{@valid_dice_str}"
            )
        end

      "!help" ->
        help_text = """
        **Comandi disponibili:**
        - `!ping` - Testa che il bot sia attivo
        - `!roll <facce> <lanci>(default=1)` - Tira dadi
        - `!help` - Mostra questo messaggio

        **Dadi supportati:** #{@valid_dice_str}

        **Esempi:**
        - Lancia 1d20: `!roll 20`
        - Lancia 3d6: `!roll 6 3`
        """

        {:ok, _message} =
          Message.create(
            msg.channel_id,
            help_text
          )

      _ ->
        :ignore
    end
  end

  defp handle_roll(msg, dice_type, rolls) do
    with {:ok, faces} <- parse_dice_type(dice_type),
         {:ok, rolls_int} <- parse_rolls(rolls) do
      results = for _ <- 1..rolls_int, do: random_in_range(faces)
      results_str = results |> Enum.map(&to_string/1) |> Enum.join(", ")

      total = results |> Enum.sum()

      {:ok, _message} =
        Message.create(
          msg.channel_id,
          "Hai tirato #{rolls}d#{dice_type}: [#{results_str}] - `Totale: #{total}`"
        )
    else
      {:error, :invalid_dice} ->
        {:ok, _message} =
          Message.create(
            msg.channel_id,
            "Tipo di dado non valido. Dadi validi: #{@valid_dice_str}"
          )

      {:error, :invalid_format} ->
        Message.create(
          msg.channel_id,
          "Formato non valido. Uso: `!roll <facce> <lanci>` - Dadi consentiti: #{@valid_dice_str}"
        )
    end
  end

  defp parse_dice_type(dice_type) do
    case Integer.parse(dice_type) do
      {faces, ""} when faces in @valid_dice ->
        {:ok, faces}

      {_faces, ""} ->
        {:error, :invalid_dice}

      _ ->
        {:error, :invalid_format}
    end
  end

  defp parse_rolls(rolls) do
    case Integer.parse(rolls) do
      {rolls_int, ""} ->
        {:ok, rolls_int}

      _ ->
        {:error, :invalid_format}
    end
  end

  def random_in_range(max) when max > 0 do
    <<random_int::unsigned-integer-32>> = :crypto.strong_rand_bytes(4)
    rem(random_int, max) + 1
  end
end
