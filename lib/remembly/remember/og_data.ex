defmodule Remembly.Remember.OgData do
  use Ash.Resource,
    otp_app: :remembly,
    domain: Remembly.Remember,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource]

  graphql do
    type :og_data
  end

  json_api do
    type "og_data"
  end

  postgres do
    table "og_datas"
    repo Remembly.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

    attribute :url, :string, allow_nil?: false, public?: true
    attribute :title, :string, public?: true
    attribute :image, :string, public?: true
    attribute :description, :string, public?: true
    attribute :site_name, :string, public?: true

    timestamps(public?: true)
  end

  relationships do
    belongs_to :memory, Remembly.Remember.Memory, public?: true
  end
end
