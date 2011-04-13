module APN
  class Group
    include MongoMapper::Document

    key :name, String
    key :app_id, BSON::ObjectId, :required => true
    key :device_ids, Array
    timestamps!
  
    belongs_to :app, :class_name => 'APN::App'
    many   :group_notifications, :class_name => 'APN::GroupNotification'
  
    def devices
      DeviceGrouping.new(self)
    end
  
    validates_uniqueness_of :name, :scope => :app_id

    def unsent_group_notifications
      group_notifications.where(:sent_at => nil).all
    end
    
  end
end
