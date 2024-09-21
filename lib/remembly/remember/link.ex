defmodule Remembly.Remember.Link do
  use Ash.Resource,
    otp_app: :remembly,
    domain: Remembly.Remember,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource]

  json_api do
    type "link"
  end

  postgres do
    table "links"
    repo Remembly.Repo
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    create :remember_link do
      accept [:url]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :url, :string, allow_nil?: false

    timestamps()
  end
end
