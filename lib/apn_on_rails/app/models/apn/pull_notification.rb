class APN::PullNotification
  include MongoMapper::Document

  key :app_id, BSON::ObjectId, :required => true
  key :title, String
  key :content, String
  key :link, String
  key :launch_notification, Boolean
  timestamps!

  belongs_to :app, :class_name => 'APN::App'
  
  def self.latest_since(app_id, since_date=nil)
    scope = where(:app_id => app_id).sort('created_at desc')
    if since_date
      res = scope.where(:created_at.gt => since_date, :launch_notification => false).first
    else
      res = scope.where(:launch_notification => true).first
      res = scope.where(:launch_notification => false).first unless res
    end
    res
  end
  
  def self.all_since(app_id, since_date=nil)
    scope = where(:app_id => app_id, :launch_notification => false).sort('created_at desc')
    scope = scope.where(:created_at.gt => since_date) if since_date
    scope.all
  end
end
