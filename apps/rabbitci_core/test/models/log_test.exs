defmodule RabbitCICore.LogTest do
  use RabbitCICore.Integration.Case
  use RabbitCICore.TestHelper

  alias RabbitCICore.Log

  test "required fields" do
    assert !Log.changeset(%Log{}, %{}).valid?
    assert !Log.changeset(%Log{}, %{stdio: "xyz"}).valid?
    assert !Log.changeset(%Log{}, %{stdio: nil, step_id: 0}).valid?
    assert Log.changeset(%Log{}, %{stdio: "xyz", step_id: 0}).valid?
  end
end
