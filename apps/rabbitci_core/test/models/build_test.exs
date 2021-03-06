defmodule RabbitCICore.BuildTest do
  use RabbitCICore.Integration.Case
  use RabbitCICore.TestHelper

  alias RabbitCICore.Repo
  alias RabbitCICore.Project
  alias RabbitCICore.Branch
  alias RabbitCICore.Build

  test "build_number must be unique in the scope of branch" do
    p1 = Project.changeset(%Project{}, %{name: "project1", repo: "repo123"})
    |> Repo.insert!
    b1 = Branch.changeset(%Branch{}, %{name: "branch1", project_id: p1.id,
                                       exists_in_git: false})
    |> Repo.insert!

    b2 = Branch.changeset(%Branch{}, %{name: "branch2", project_id: p1.id,
                                       exists_in_git: false})
    |> Repo.insert!

    build = Repo.insert! Build.changeset(%Build{}, %{build_number: 1,
                                                    branch_id: b1.id,
                                                    commit: "xyz"})
    assert !Build.changeset(%Build{}, %{build_number: 1,
                                        branch_id: b1.id,
                                        commit: "xyz"}).valid?

    assert Build.changeset(%Build{}, %{build_number: 1,
                                       branch_id: b2.id,
                                       commit: "xyz"}).valid?
  end

  test "status" do
    assert Build.status(["queued", "queued", "queued"]) == "queued"
    assert Build.status(["running", "queued", "error"]) == "error"
    assert Build.status(["running", "running", "failed"]) == "failed"
    assert Build.status(["queued", "queued", "finished"]) == "running"
    assert Build.status(["queued", "queued", "running"]) == "running"
    assert Build.status(["finished", "finished", "finished"]) == "finished"
    assert Build.status([]) == "queued"
  end
end
