defmodule Remembly.Remember.Message do
  use Ash.Resource,
    otp_app: :remembly,
    domain: Remembly.Remember,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource]

  require Ash.Expr

  json_api do
    type "message"
  end

  postgres do
    table "messages"
    repo Remembly.Repo
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    create :remember_message do
      primary? true
      accept [:reference_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :reference_id, :string, allow_nil?: false

    timestamps(public?: true)
  end

  relationships do
    belongs_to :memory, Remembly.Remember.Memory, public?: true
  end

  identities do
    identity :message_reference_id, [:reference_id]
  end
end
