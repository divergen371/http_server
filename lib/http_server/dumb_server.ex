defmodule HttpServer.DumbServer do
  use GenServer

  require Logger

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    Logger.info("Start dumb server with supervisor at #{port} port")

    {:ok, listen} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    HttpServer.Dumb.loop_acceptor(listen)
    {:ok, port}
  end
end
