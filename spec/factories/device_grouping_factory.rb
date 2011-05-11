module DeviceGroupingFactory
  
  class << self
    
    def new(options = {})
      device = APN::Device.first
      group  = APN::Group.first
      options = {:device_id => device ? device.id : nil, :group_id => group ? group.id : nil}.merge(options)
      return APN::DeviceGrouping.new(options)
    end
    
    def create(options = {})
      device_grouping = DeviceGroupingFactory.new(options)
      device_grouping.save
      return device_grouping
    end
    
  end
  
end

DeviceGroupingFactory.create