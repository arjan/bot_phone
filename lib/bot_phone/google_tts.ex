defmodule BotPhone.GoogleTTS do
  @scope "https://www.googleapis.com/auth/cloud-platform"
  @url "https://texttospeech.googleapis.com/v1beta1/text:synthesize"

  def synthesize(text) do
    {:ok, %Goth.Token{token: token}} = Goth.Token.for_scope(@scope)

    body =
      %{
        audioConfig: %{
          audioEncoding: "MP3",
          pitch: "0.00",
          speakingRate: "1.00"
        },
        input: %{
          text: text
        },
        voice: %{
          languageCode: "nl-NL",
          name: "nl-NL-Wavenet-A"
        }
      }
      |> Poison.encode!()

    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.request(:post, @url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: status, body: body}} when status in 200..299 ->
        {:ok, Poison.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status, body: body}} when status >= 300 ->
        {:error, Poison.decode!(body)}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
