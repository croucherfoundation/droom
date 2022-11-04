gem 'colorize'
require 'colorize'
require 'sidekiq/api'

namespace :droom do

  task :dequeues => :environment do
    print "* Purging queues..."
    Sidekiq::Queue.all.map(&:clear)
    print " done\n".colorize(:green)
  end

  task :reindex => :environment do
    %w{User Organisation Document Tag}.each do |classname|
      print "* Indexing #{classname}..."
      klass = "Droom::#{classname}".constantize
      klass.searchkick_index.delete if klass.searchkick_index
      klass.reindex
      print " done\n".colorize(:green)
    end
  end

  task :add_file_url => :environment do
    Droom::Document.find_in_batches(batch_size: 100).each do |documents|
      documents.each do |doc|
        if doc.folder.present? && doc.folder.ancestors.last.try(:name) == "Events"
          doc.file_full_path = doc.folder.folder_path.tr(" ", "_")
          doc.event_id = doc.folder.event.try(:id)
          doc.save(:validate => false)
          Rails.logger.info(doc.errors.full_messages.to_sentence) 
          print "ID : #{doc.id} done\n".colorize(:green)
        end
      end
    end
  end


end