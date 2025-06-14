defmodule Remembly.Remember.Category do
  use Ash.Resource,
    otp_app: :remembly,
    domain: Remembly.Remember,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource]

  require Ash.Expr

  json_api do
    type "category"
  end

  postgres do
    table "categories"
    repo Remembly.Repo
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    create :remember_category do
      accept [:label]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :label, :string, allow_nil?: false, public?: true

    timestamps(public?: true)
  end

  relationships do
    has_many :messages, Remembly.Remember.Message, public?: true
  end
end
