defmodule HttpServer.Hello do
  require Logger

  def start(port \\ 8000) do
    Logger.info("Start Hello Server on #{port} port ...")

    {:ok, listen} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    loop_acceptor(listen)
  end

  def loop_acceptor(listen) do
    {:ok, accept_sock} = :gen_tcp.accept(listen)
    handle_server(accept_sock)
    loop_acceptor(listen)
  end

  def handle_server(accept) do
    case read_req(accept) do
      {:req_line, _method, _target, _prot_ver} ->
        handle_server(accept)

      {:header_line, _header_field, _header_val} ->
        handle_server(accept)

      :req_end ->
        send_resp(accept)
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

      _body ->
        :req_end
    end
  end

  def send_resp(accept) do
    msg = "Hello Elixir"

    resp_msg = """
    HTTP/1.1 200 OK
    Content-Length: #{String.length(msg)}

    #{msg}
    """

    :gen_tcp.send(accept, resp_msg)
    :gen_tcp.close(accept)
  end
end