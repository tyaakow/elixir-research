defmodule Aehttpserver.TxController do
  use Aehttpserver.Web, :controller
  alias Aecore.Txs.Pool.Worker, as: Pool
  alias Aecore.Utils.Serialization, as: Serialization

  def show(conn, params) do
    account_bin =
      params["account"]
      |> Base.decode16!()
    IO.inspect account_bin
    user_txs = Pool.get_txs_for_address(account_bin)
    IO.inspect user_txs
    json(conn , Enum.map(user_txs, fn(tx) ->
          %{tx |
            from_acc: Serialization.hex_binary(tx.from_acc, :serialize),
            to_acc: Serialization.hex_binary(tx.to_acc, :serialize)
           } end))
  end

end
