defmodule RabbitCICore.Log do
  use RabbitCICore.Web, :model

  alias RabbitCICore.Step

  schema "logs" do
    field :stdio, :string
    field :order, :integer

    belongs_to :step, Step

    timestamps
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If `params` are nil, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ nil) do
    cast(model, params, ~w(stdio step_id), ~w())
  end
end
