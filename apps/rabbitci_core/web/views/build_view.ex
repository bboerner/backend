defmodule RabbitCICore.BuildView do
  use RabbitCICore.Web, :view

  alias RabbitCICore.BuildSerializer

  def render("index.json", %{conn: conn, builds: builds}) do
    BuildSerializer.format(builds, conn, %{})
  end

  def render("show.json", %{conn: conn, build: build}) do
    BuildSerializer.format(build, conn, %{})
  end

  def render("config.json", %{build: build, project: project, branch: branch}) do
    config = Poison.decode!(build.config_file.raw_body)
    env = %{"BRANCH" => branch.name, "COMMIT" => build.commit,
            "PROJECT_NAME" => project.name, "BUILD_NUMBER" => build.build_number,
            "REPO" => project.repo}

    env = Map.merge(config["ENV"], expand_env_vars(env))
    Map.put(config, "ENV", env)
    |> merge_script_envs
  end

  defp expand_env_vars(env_vars) do
    Enum.map(env_vars, fn({key, value}) ->
      {"RABBIT_CI_" <> key, value}
    end) |> Enum.into(%{})
  end

  defp merge_script_envs(config = %{"ENV" => global, "scripts" => scripts}) do
    new_scripts = Enum.map(scripts, fn(script) ->
      new_env = Map.merge(global, script["ENV"] || %{})
      Map.put(script, "ENV", new_env)
    end)

    Map.put(config, "scripts", new_scripts)
    |> Map.delete("ENV")
  end
end
