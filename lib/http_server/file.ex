defmodule HttpServer.File do
  require Logger

  def start(port \\ 8000) do
    Logger.info("Start server at #{port}.")

    {:ok, listen} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    loop_acceptor(listen)
  end

  def loop_acceptor(listen) do
    {:ok, accept} = :gen_tcp.accept(listen)
    handle_server(accept)
    loop_acceptor(listen)
  end

  def handle_server(accept, conn \\ %{}) do
    case read_req(accept) do
      {:req_line, method, target, prot_ver} ->
        conn =
          conn
          |> Map.put(:method, method)
          |> Map.put(:target, target)
          |> Map.put(:prot_ver, prot_ver)

        handle_server(accept, conn)

      {:header_line, header_field, header_val} ->
        conn =
          conn
          |> Map.put(header_field, header_val)

        handle_server(accept, conn)

      :req_end ->
        send_resp(accept, conn)
    end
  end

  def read_req(accept) do
    {:ok, raw_msg} = :gen_tcp.recv(accept, 0)
    req_msg = String.trim(raw_msg)

    case String.split(req_msg, " ") do
      [method, target, prot_ver] ->
        {:req_line, method, target, prot_ver}

      [header_field, header_val] ->
        {:header_line, header_field, header_val}

      _ ->
        :req_end
    end
  end

  def send_resp(accept, conn) do
    resp_msg = build_res_msg(conn)

    :gen_tcp.send(accept, resp_msg)
    :gen_tcp.close(accept)
  end

  def build_res_msg(conn) do
    target = "#{File.cwd!()}/priv#{Map.get(conn, :target)}"
    Logger.info("file: #{target} ---> exists? [#{File.exists?(target)}]")

    {status_code, status_msg, body} =
      case File.exists?(target) do
        true ->
          {200, "OK", File.read!(target)}

        false ->
          {404, "Not Found", "404 Not Found"}

        _else ->
          {500, "Internal Server Error", "Oh No."}
      end

    """
    HTTP/1.1 #{status_code} #{status_msg}

    #{body}
    """
  end
end
