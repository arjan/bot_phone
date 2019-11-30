defmodule BotPhone.UrlCache do
  def url_to_file(url) do
    prefix = file_prefix(url)

    case Path.wildcard(prefix <> "*") do
      [file | _] ->
        file

      [] ->
        case HTTPoison.get(url, [], http_opts()) do
          {:ok, %{status_code: 200, headers: headers, body: body}} ->
            filename = prefix
            File.write!(filename, body)
            filename
        end
    end
  end

  defp http_opts() do
    [follow_redirect: true, max_redirect: 3, timeout: 30_000, recv_timeout: 30_000]
  end

  defp file_prefix(url) do
    Path.join("/tmp", :crypto.hash(:sha, url) |> Base.encode16(case: :lower))
  end
end
