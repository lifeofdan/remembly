defmodule Remembly.Remember.Website do
  use Ash.Resource,
    otp_app: :remembly,
    domain: Remembly.Remember,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource]

  graphql do
    type :website
  end

  postgres do
    table "websites"
    repo Remembly.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    create :remember_website do
      primary? true
      accept [:url]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :url, :string, allow_nil?: false, public?: true

    timestamps(public?: true)
  end

  relationships do
    belongs_to :memory, Remembly.Remember.Memory, public?: true
  end

  identities do
    identity :website_url, [:url]
  end
end
