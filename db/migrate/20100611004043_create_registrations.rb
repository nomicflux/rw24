class CreateRegistrations < ActiveRecord::Migration
  def self.up
    create_table :registrations do |t|
      t.boolean :paid, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :registrations
  end
end
