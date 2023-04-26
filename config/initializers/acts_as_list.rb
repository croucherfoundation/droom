Rails.application.reloader.to_prepare do
  ActiveRecord::Acts::List::InstanceMethods.module_eval do

    def decrement_positions_on_lower_items(position=current_position)
      
      if self.class == Droom::Document
        documents = self.folder.documents.where('position > ? && folder_id = ?', position, self.folder_id)  
        documents.map{|d| d.update_columns(position: d.position - 1)}

        puts 'reposition after a document deleted'
      else
        return unless in_list?

        if sequential_updates?
          acts_as_list_list.where("#{quoted_position_column_with_table_name} > ?", position).reorder(acts_as_list_order_argument(:asc)).decrement_sequentially
        else
          acts_as_list_list.where("#{quoted_position_column_with_table_name} > ?", position).decrement_all
        end
      end

    end
  end
end