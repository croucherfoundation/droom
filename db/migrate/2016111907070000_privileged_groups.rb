class PrivilegedGroups < ActiveRecord::Migration
  def change
    add_column :droom_groups, :privileged, :boolean, default: false
    add_index :droom_groups, :privileged
    add_column :droom_documents, :private, :boolean, default: false
    add_column :droom_documents, :public, :boolean, default: false
    add_index :droom_documents, :private
    add_index :droom_documents, :public
  end
end
