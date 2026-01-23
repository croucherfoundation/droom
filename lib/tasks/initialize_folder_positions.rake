namespace :droom do
  namespace :folders do
    desc "Initialize position values for all folders grouped by ancestry"
    task initialize_positions: :environment do
      puts "Initializing folder positions..."
      
      # Group folders by ancestry (nil for root folders, parent path for children)
      Droom::Folder.where(position: nil).group_by(&:ancestry).each do |ancestry, folders|
        puts "Processing #{folders.count} folders with ancestry: #{ancestry.inspect}"
        
        # Order by ID (preserves current order) and assign positions
        folders.sort_by(&:id).each_with_index do |folder, index|
          position = index + 1
          folder.update_column(:position, position)
          puts "  - Set #{folder.name} (ID: #{folder.id}) to position #{position}"
        end
      end
      
      puts "Done! Initialized positions for all folders."
    end
  end
end
