module APN
  class DeviceGrouping < ::BasicObject
    def initialize(group)
      @group = group
    end

    def <<(device)
      return device if @group.device_ids.include?(device.id)
      @group.device_ids << device.id
      @group.collection.update({:_id => @group.id}, {:$addToSet => {:device_ids => device.id}})
      device
    end

    def delete(device)
      return device unless @group.device_ids.include?(device.id)
      @group.device_ids.delete(device.id)
      @group.collection.update({:_id => @group.id}, {:$pull => {:device_ids => device.id}})
      device
    end
  
    protected
    def method_missing(method, *args, &block)
      if Device.respond_to?(method)
        Device.where(:_id => @group.device_ids).send(method, *args, &block)
      else
        super
      end
    end
  end
end
