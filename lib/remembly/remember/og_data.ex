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
    defaults [:read, :update, :destroy]

    create :create_og_data do
      accept [:url, :title, :description, :site_name, :image]

      argument :memory_id, :uuid, allow_nil?: false

      change manage_relationship(:memory_id, :memory, type: :append_and_remove)
    end
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
    belongs_to :memory, Remembly.Remember.Memory, allow_nil?: false, public?: true
  end
end
