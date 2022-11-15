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

end