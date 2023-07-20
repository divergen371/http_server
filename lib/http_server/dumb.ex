defmodule HttpServer.Dumb do
  require Logger

  def start(port \\ 8000) do
    Logger.info("Start dumb server on port #{port}")

    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    loop_acceptor(socket)
  end

  def loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    loop_acceptor(socket)
  end

  def serve(socket) do
    case read_line(socket) do
      :closed ->
        Logger.info("Server closed")
        :gen_tcp.close(socket)

      line ->
        serve(socket)
    end
  end

  def read_line(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, line} ->
        IO.puts(String.trim(line))

      {:error, :closed} ->
        Logger.info("read_line: Server Closed")
        :closed
    end
  end

  def write_line(line, socket) do
    Logger.info("write_line: #{line}")
    :gen_tcp.send(socket, line)
  end
end
