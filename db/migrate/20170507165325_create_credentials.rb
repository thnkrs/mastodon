class CreateCredentials < ActiveRecord::Migration[5.0]
  def change
    create_table :credentials do |t|
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false

      t.belongs_to :user, index: true

      t.timestamps
    end
  end
end
