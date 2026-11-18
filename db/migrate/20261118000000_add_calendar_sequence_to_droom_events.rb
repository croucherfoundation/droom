class AddCalendarSequenceToDroomEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :droom_events, :calendar_sequence, :integer, null: false, default: 0
  end
end
