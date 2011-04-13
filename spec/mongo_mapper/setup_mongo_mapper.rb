require 'rubygems'
require 'mongo_mapper'

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

config = {'test' => {'host' => 'localhost', 'port' => 27017, 'database' => 'apn_on_rails_test'}}
MongoMapper.setup(config, 'test', :logger => logger)

module MongoMapper
  module Plugins
    module Querying
      module Decorator
        def find_each(opts={})
          cursor = super
          if block_given?
            cursor.each{|doc| yield model.load(doc)}
          end
          cursor
        end
      end
    end
  end
end
