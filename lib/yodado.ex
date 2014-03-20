defmodule Yodado do
  use Application.Behaviour

  def start(_type, _args) do
    start_web()
    start_thrift()
    start_mnesia()
    {:ok, self()}
  end

  defp start_web() do
    {:ok, _cowboy_pid} = Yodado.Web.start()
  end

  defp start_thrift() do
    :thrift_socket_server.start(
      handler: Yodado.Transport.FeaturesThriftHandler,
      service: :features_thrift,
      port: 12345)
  end

  # debugging only, kill this shortly
  def test_thrift() do
    {:ok, c} = :thrift_client_util.new('localhost', 12345, :features_thrift, [])
    {c, {:ok, pong}} = :thrift_client.call(c, :ping, [])
    IO.puts "ping=#{pong}"

    args = :dict.from_list([{"ip", "1.2.3.4"}, {"username", "madlep"}])
    {c,{:ok, features_dict}} = :thrift_client.call(c, :feature_set, [args])
    features = :dict.to_list(features_dict)
    IO.puts "feature_set=#{inspect(features)}"

    {c, :ok} = :thrift_client.close(c) 
    :ok
  end

  defp start_mnesia() do
   {:ok, data_dir} = :application.get_env(:yodado, :data_dir)
   :application.set_env(:mnesia, :dir, data_dir)
   :ok = :mnesia.start()
  end

end
