defmodule RabbitCICore.BuildControllerTest do
  use RabbitCICore.Integration.Case
  use RabbitCICore.TestHelper

  alias RabbitCICore.Project
  alias RabbitCICore.Branch
  alias RabbitCICore.Repo
  alias RabbitCICore.ConfigFile
  alias RabbitCICore.Build
  alias Ecto.Model

  # TODO: Test bad params
  def generate_records(builds: amount) do
    project = Repo.insert!(%Project{name: "blah", repo: "lala"})
    branch = Repo.insert!(%Branch{name: "branch1", project_id: project.id})
    time = Ecto.DateTime.utc()
    builds = for _ <- 1..amount do
      Model.build(branch, :builds,
                  %{start_time: time,
                    finish_time: time,
                    commit: "eccee02ec18a36bcb2615b8c86d401b0618738c2"})
      |> Build.changeset
      |> Repo.insert!
    end

    {project, branch, builds}
  end

  test "page offset should default to 0" do
    {project, branch, _} = generate_records(builds: 40)
    url = "/projects/#{project.name}/branches/#{branch.name}/builds"
    response = get(url)
    body = Poison.decode!(response.resp_body)
    assert hd(body["data"])["attributes"]["build-number"] == 40
    assert List.last(body["data"])["attributes"]["build-number"] == 11
  end

  test "page offset should work" do
    {project, branch, _} = generate_records(builds: 40)
    url = "/projects/#{project.name}/branches/#{branch.name}/builds"
    response = get(url, [page: %{offset: "1"}])
    body = Poison.decode!(response.resp_body)
    assert hd(body["data"])["attributes"]["build-number"] == 10
    assert List.last(body["data"])["attributes"]["build-number"] == 1
  end

  test "show a single build" do
    {project, branch, _} = generate_records(builds: 1)
    url = "/projects/#{project.name}/branches/#{branch.name}/builds/1"
    response = get(url)
    body = Poison.decode!(response.resp_body)
    assert is_map(body)
  end

  test "get config file" do
    config = %{"ENV" => %{"VAR1" => "VAR1 Global"},
               "scripts" => [%{"ENV" => %{"SOMETHING" => "Just a variable"},
                               "name" => "main"},
                             %{"ENV" => %{"VAR1" => "Override global var"},
                               "name" => "override-VAR1"}]}
    |> Poison.encode!

    expected =
      %{"scripts" =>
         [%{"ENV" =>
             %{"RABBIT_CI_BRANCH" => "branch1",
               "RABBIT_CI_BUILD_NUMBER" => 1,
               "RABBIT_CI_COMMIT" => "eccee02ec18a36bcb2615b8c86d401b0618738c2",
               "RABBIT_CI_PROJECT_NAME" => "blah", "RABBIT_CI_REPO" => "lala",
               "SOMETHING" => "Just a variable", "VAR1" => "VAR1 Global"},
            "name" => "main"},
          %{"ENV" =>
             %{"RABBIT_CI_BRANCH" => "branch1", "RABBIT_CI_BUILD_NUMBER" => 1,
               "RABBIT_CI_COMMIT" => "eccee02ec18a36bcb2615b8c86d401b0618738c2",
               "RABBIT_CI_PROJECT_NAME" => "blah", "RABBIT_CI_REPO" => "lala",
               "VAR1" => "Override global var"}, "name" => "override-VAR1"}]}

    {project, branch, builds} = generate_records(builds: 1)
    build = hd(builds)
    Repo.insert!(%ConfigFile{build_id: build.id, raw_body: config})
    url = ("/projects/#{project.name}/branches/#{branch.name}/builds/" <>
      "#{build.build_number}/config")
    response = get(url)
    assert Poison.decode!(response.resp_body) == expected
  end
end
