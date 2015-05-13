defmodule Rabbitci.QueueControllerTest do
  use Rabbitci.Integration.Case
  use Rabbitci.TestHelper

  import Mock
  import Ecto.Query

  alias Rabbitci.Repo
  alias Rabbitci.Project
  alias Rabbitci.Branch
  alias Rabbitci.Build

  test "missing params" do
    response = post("/queue")
    assert response.status == 400
  end

  test "no project with repo" do
    response = post("/queue", %{repo: "xyz", commit: "xyz", branch: "xyz"})
    assert response.status == 404
  end

  test "branch does not exist" do
    project = Repo.insert %Project{name: "project1", repo: "xyz"}
    response = post("/queue", %{repo: "xyz", commit: "xyz", branch: "xyz"})
    assert response.status == 200
    query = (from b in Branch,
             where: b.project_id == ^project.id and b.name == "xyz")
    assert Repo.one(query) != nil
  end

  test "successful queue" do
    with_mock Exq, [enqueue: fn(_, _, _ , _) -> nil end] do
      p = Repo.insert %Project{name: "project1", repo: "xyz"}
      b = Repo.insert %Branch{name: "branch1", exists_in_git: false,
                              project_id: p.id}
      response = post("/queue", %{repo: "xyz", commit: "xyz",
                                  branch: "branch1"})
      assert response.status == 200
      assert called Exq.enqueue(:_, :_, :_, :_)
      query = (from b in Build,
               where: b.branch_id == ^b.id and b.commit == "xyz")
      assert Repo.one(query) != nil
    end
  end
end