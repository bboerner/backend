defmodule Rabbitci.BranchSerializer do
  use Remodel

  @array_root :branches
  require Rabbitci.SerializerHelpers
  alias Rabbitci.SerializerHelpers

  attributes [:id, :updated_at, :inserted_at, :name, :build_ids, :build_url]

  def build_ids(record), do: Rabbitci.Branch.build_ids(record)
  def build_url(m, conn) do
    Rabbitci.Router.Helpers.build_path(conn, :index, m.project_id, m.id)
  end

  SerializerHelpers.time(updated_at, Rabbitci.Branch)
  SerializerHelpers.time(inserted_at, Rabbitci.Branch)

end