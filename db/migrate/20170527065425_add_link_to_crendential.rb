class AddLinkToCrendential < ActiveRecord::Migration[5.0]
  def change
    add_column :credentials, :link, :string, null: true
  end
end
