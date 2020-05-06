defmodule Spades.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, null: false
      add :password, :string
      add :password_hash, :string
      add :last_login, :utc_datetime

      timestamps()
    end

    create unique_index(:users, [:username])
  end
end
