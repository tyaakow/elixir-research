defmodule Aecore.Utils.Blockchain.BlockValidation do

  alias Aecore.Keys.Worker, as: KeyManager
  alias Aecore.Pow.Hashcash

  @spec validate_block(%Aecore.Structures.Block{},
                       %Aecore.Structures.Block{}) :: {:error, term()} | :ok
  def validate_block(new_block, previous_block) do
    new_block_header_hash = block_header_hash(new_block)
    prev_block_header_hash = block_header_hash(previous_block)
    is_difficulty_target_met = Hashcash.verify(new_block.header,
      new_block.header.difficulty_target)

    cond do
      new_block.header.prev_hash != prev_block_header_hash ->
        {:error, "Incorrect previous hash"}
      previous_block.header.height + 1 != new_block.header.height ->
        {:error, "Incorrect height"}
      !is_difficulty_target_met ->
        {:error, "Header hash doesnt meet the difficulty target"}
      new_block.header.txs_hash != calculate_root_hash(new_block) ->
        {:error, "Root hash of transactions does not match the one in header"}
      !(new_block |> validate_block_transactions |> Enum.all?) ->
        {:error, "One or more transactions not valid"}
      true ->
        :ok
    end
  end

  @spec block_header_hash(%Aecore.Structures.Block{}) :: binary()
  def block_header_hash (block) do
    block_header_bin = :erlang.term_to_binary(block.header)
    :crypto.hash(:sha256, block_header_bin)
  end

  @spec validate_block_transactions(%Aecore.Structures.Block{}) :: term()
  def validate_block_transactions(block) do
    for transaction <- block.txs do
      KeyManager.verify(transaction.data,
                        transaction.signature,
                        transaction.data.from_acc)
    end
  end

  @spec calculate_root_hash(%Aecore.Structures.Block{}) :: binary()
  def calculate_root_hash(block) do
    if(length(block.txs ) == 0) do
      <<0::256>>
    else
      merkle_tree = :gb_merkle_trees.empty
      merkle_tree = for transaction <- block.txs do
        transaction_data_bin = :erlang.term_to_binary(transaction.data)
        {:crypto.hash(:sha256, transaction_data_bin), transaction_data_bin}
      end
      merkle_tree = merkle_tree |>
        List.foldl(:gb_merkle_trees.empty, fn(node, merkle_tree)
        -> :gb_merkle_trees.enter(elem(node,0), elem(node,1) , merkle_tree) end)
      merkle_tree |> :gb_merkle_trees.root_hash()
    end
  end

end
