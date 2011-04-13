class APN::App
  include MongoMapper::Document
  key :app_dev_cert, String
  key :app_prod_cert, String
  timestamps!
  
  many :groups, :class_name => 'APN::Group', :dependent => :destroy
  many :devices, :class_name => 'APN::Device', :dependent => :destroy
    
  def cert
    (RAILS_ENV == 'production' ? apn_prod_cert : apn_dev_cert)
  end
  
  # Opens a connection to the Apple APN server and attempts to batch deliver
  # an Array of group notifications.
  # 
  # 
  # As each APN::GroupNotification is sent the <tt>sent_at</tt> column will be timestamped,
  # so as to not be sent again.
  # 
  def send_notifications
    if self.cert.nil?
      raise APN::Errors::MissingCertificateError.new
      return
    end
    APN::App.send_notifications_for_cert(self.cert, self.id)
  end
  
  def self.send_notifications
    apps = APN::App.all 
    apps.each do |app|
      app.send_notifications
    end
    if !configatron.apn.cert.blank?
      global_cert = File.read(configatron.apn.cert)
      send_notifications_for_cert(global_cert, nil)
    end
  end
  
  def self.send_notifications_for_cert(the_cert, app_id)
    # unless self.unsent_notifications.nil? || self.unsent_notifications.empty?
      begin
        APN::Connection.open_for_delivery({:cert => the_cert}) do |conn, sock|
          APN::Device.find_each(:app_id => app_id) do |dev|
            dev.unsent_notifications.each do |noty|
              conn.write(noty.message_for_sending)
              noty.sent_at = Time.now
              noty.save
            end
          end
        end
      rescue Exception => e
        log_connection_exception(e)
      end
    # end   
  end
  
  def send_group_notifications
    if self.cert.nil? 
      raise APN::Errors::MissingCertificateError.new
      return
    end
    unless self.unsent_group_notifications.nil? || self.unsent_group_notifications.empty? 
      APN::Connection.open_for_delivery({:cert => self.cert}) do |conn, sock|
        unsent_group_notifications.each do |gnoty|
          gnoty.devices.find_each do |device|
            conn.write(gnoty.message_for_sending(device))
          end
          gnoty.sent_at = Time.now
          gnoty.save
        end
      end
    end
  end
  
  def send_group_notification(gnoty)
    if self.cert.nil? 
      raise APN::Errors::MissingCertificateError.new
      return
    end
    unless gnoty.nil?
      APN::Connection.open_for_delivery({:cert => self.cert}) do |conn, sock|
        gnoty.devices.find_each do |device|
          conn.write(gnoty.message_for_sending(device))
        end
        gnoty.sent_at = Time.now
        gnoty.save
      end
    end
  end
  
  def self.send_group_notifications
    apps = APN::App.all
    apps.each do |app|
      app.send_group_notifications
    end
  end          
  
  # Retrieves a list of APN::Device instnces from Apple using
  # the <tt>devices</tt> method. It then checks to see if the
  # <tt>last_registered_at</tt> date of each APN::Device is
  # before the date that Apple says the device is no longer
  # accepting notifications then the device is deleted. Otherwise
  # it is assumed that the application has been re-installed
  # and is available for notifications.
  # 
  # This can be run from the following Rake task:
  #   $ rake apn:feedback:process
  def process_devices
    if self.cert.nil?
      raise APN::Errors::MissingCertificateError.new
      return
    end
    APN::App.process_devices_for_cert(self.cert)
  end # process_devices
  
  def self.process_devices
    apps = APN::App.all
    apps.each do |app|
      app.process_devices
    end
    if !configatron.apn.cert.blank?
      global_cert = File.read(configatron.apn.cert)
      APN::App.process_devices_for_cert(global_cert)
    end
  end
  
  def self.process_devices_for_cert(the_cert)
    puts "in APN::App.process_devices_for_cert"
    APN::Feedback.devices(the_cert).each do |device|
      if device.last_registered_at < device.feedback_at
        puts "device #{device.id} -> #{device.last_registered_at} < #{device.feedback_at}"
        device.destroy
      else 
        puts "device #{device.id} -> #{device.last_registered_at} not < #{device.feedback_at}"
      end
    end 
  end

  def unsent_notifications
    devices.inject([]) {|notifications, device| notifications.concat(device.unsent_notifications)}
  end

  def unsent_group_notifications
    groups.inject([]) {|notifications, group| notifications.concat(group.unsent_group_notifications)}
  end
  
  
  protected
  def log_connection_exception(ex)
    puts ex.message
  end
    
end
