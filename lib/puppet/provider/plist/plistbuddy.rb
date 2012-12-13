Puppet::Type.type(:plist).provide :plistbuddy, :parent => Puppet::Provider do

  desc "This provider alters plist values using the PlistBuddy(8) command line utility.

  Because of the way that PlistBuddy deals with types, it cannot convert an existing Plist key from one type to another.
  The key must first be removed in order to change the type of value it contains.

  There also seems to be no documentation about the appropriate date format.
  "

  commands :plistbuddy => "/usr/libexec/PlistBuddy"
  confine :operatingsystem => :darwin

  mk_resource_methods

  class << self

    def prefetch(resources)
      resources.each do |name, resource|
        if File.exist? resource.filename

          begin
            file_path = resource.filename
            keys = resource.keys

            print_cmd = "Print :%s" % keys.join(':')
            print_value = plistbuddy(file_path, '-c', print_cmd).strip

            prefetched_values = {
                :name     => name,
                :ensure   => :present
            }

            case resource[:value_type]
              when :real
                prefetched_values[:value] = print_value.to_f
              when :date
                prefetched_values[:value] = Date.new(print_value)
              else
                prefetched_values[:value] = print_value
            end

            resource.provider = new(prefetched_values)

          rescue Exception => e # Command exit status was bad, assume the plist key doesn't exist
            resource.provider = new({ :ensure => :absent })
          end
        else # File doesn't exist therefore plist key doesn't exist
          resource.provider = new({ :ensure => :absent })
        end
      end
    end

  end

  def create
    @property_hash[:ensure] = :present
    self.class.resource_type.validproperties.each do |property|
      if val = resource.should(property)
        @property_hash[property] = val
      end
    end
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] != :absent
  end

  def flush

    file_path = resource.filename
    keys = resource.keys
    value_type = resource[:value_type]

    case resource[:ensure]
      when :absent
        begin
          delete_cmd = "Delete :%s" % keys.join(':')
          plistbuddy(file_path, '-c', delete_cmd)
        rescue Exception => e
          false
        end

      when :present
        begin
          # Resource WAS absent
          if @property_hash[:ensure] == :absent
            buddy_cmd = "Add :%s %s " % [ keys.join(':'), value_type ]
          else
            buddy_cmd = "Set :%s " % [ keys.join(':') ]
          end

          case value_type
            when :array
              fail('The Plistbuddy provider does not support structured values.')
              # Add the array entry
              #buddy_cmd << "%s" % [ @resource[:value] ]
              #
              ## Add the elements
              #@property_hash[:value].each do |value|
              #  plistbuddy(file_path, '-c', buddy_cmd)
              #  buddy_cmd = "Add :%s:0 %s %s" % [ keys.join(':'), 'string', value ]
              #end
            when :date # Example of a date that PlistBuddy will accept Mon Jan 01 00:00:00 EST 4001
              native_date = Date.parse(@resource[:value])
              # Note that PlistBuddy will only accept certain timezone formats like 'EST' or 'GMT' but not other valid
              # timezones like 'PST'. So the compromise is that times must be in UTC
              buddy_cmd << "%s" % [ native_date.strftime('%a %b %d %H:%M:%S %Y') ]
            when :real # The precision of the number returned and the one supplied may not be the same.
              buddy_cmd << @property_hash[:value].to_f.to_s
            else
              buddy_cmd << @resource[:value].to_s
          end

          debug(buddy_cmd)

          plistbuddy(file_path, '-c', buddy_cmd)

        rescue Exception => e
          debug(e.message)
          false
        end
    end

    @property_hash.clear
  end

  #def value
  #  begin
  #    file_path = @resource.filename
  #    keys = @resource.keys
  #
  #    buddycmd = "Print :%s" % keys.join(':')
  #    buddyvalue = plistbuddy(file_path, '-c', buddycmd).strip
  #
  #    # TODO: Compare the elements of the array by parsing the output from PlistBuddy
  #    # TODO: Convert desired dates into a format that can be compared by value.
  #    # TODO: Find a way of comparing Real numbers by casting to Float etc.
  #    case @resource.value_type
  #      when :array
  #        @resource[:value] # Assume the existence of the array even if the elements are different. Otherwise we need to parse the output
  #      when :real
  #        @resource[:value] # Assume the existence of the real number because the actual value will be stored differently.
  #      when :date
  #        @resource[:value] # Assume the existence of the date is enough. This is because the timezone will be converted upon adding the date.
  #      else
  #        buddyvalue
  #    end
  #
  #  rescue Exception => e
  #    # A bad return value from plistbuddy indicates that the key does not exist.
  #    nil
  #  end
  #end
  #
  #def value=(value)
  #  begin
  #
  #    file_path = @resource.filename
  #    keys = @resource.keys
  #    value_type = @resource.value_type
  #
  #    if value_type == :array
  #
  #      # Add the array entry
  #      buddycmd = "Add :%s %s %s" % [ keys.join(':'), value_type, @resource[:value] ]
  #
  #      # Add the elements
  #      @resource[:value].each do |value|
  #        plistbuddy(file_path, '-c', buddycmd)
  #        buddycmd = "Add :%s:0 %s %s" % [ keys.join(':'), 'string', value ]
  #      end
  #    elsif value_type == :date # Example of a date that PlistBuddy will accept Mon Jan 01 00:00:00 EST 4001
  #      native_date = Date.parse(@resource[:value])
  #      # Note that PlistBuddy will only accept certain timezone formats like 'EST' or 'GMT' but not other valid
  #      # timezones like 'PST'. So the compromise is that times must be in UTC
  #      buddycmd = "Add :%s %s %s" % [ keys.join(':'), value_type,  native_date.strftime('%a %b %d %H:%M:%S %Y')]
  #    else
  #      buddycmd = "Add :%s %s %s" % [ keys.join(':'), value_type, @resource[:value] ]
  #    end
  #
  #    plistbuddy(file_path, '-c', buddycmd)
  #
  #  rescue Exception => e
  #    false
  #  end
  #end

  #def create
  #    begin
  #      file_path = @resource.filename
  #      keys = @resource.keys
  #      value_type = @resource.value_type
  #
  #      if value_type == :array
  #
  #        # Add the array entry
  #        buddycmd = "Add :%s %s %s" % [ keys.join(':'), value_type, @resource[:value] ]
  #
  #        # Add the elements
  #        @resource[:value].each do |value|
  #          plistbuddy(file_path, '-c', buddycmd)
  #          buddycmd = "Add :%s:0 %s %s" % [ keys.join(':'), 'string', value ]
  #        end
  #      elsif value_type == :date # Example of a date that PlistBuddy will accept Mon Jan 01 00:00:00 EST 4001
  #        native_date = Date.parse(@resource[:value])
  #        # Note that PlistBuddy will only accept certain timezone formats like 'EST' or 'GMT' but not other valid
  #        # timezones like 'PST'. So the compromise is that times must be in UTC
  #        buddycmd = "Add :%s %s %s" % [ keys.join(':'), value_type,  native_date.strftime('%a %b %d %H:%M:%S %Y')]
  #      else
  #        buddycmd = "Add :%s %s %s" % [ keys.join(':'), value_type, @resource[:value] ]
  #      end
  #
  #      plistbuddy(file_path, '-c', buddycmd)
  #
  #    rescue Exception => e
  #      false
  #    end
  #end
  #
  #def destroy
  #  begin
  #    file_path = @resource.filename
  #    keys = @resource.keys
  #
  #    buddycmd = "Delete :%s" % keys.join(':')
  #    plistbuddy(file_path, '-c', buddycmd)
  #  rescue Exception => e
  #    false
  #  end
  #end
  #
  #def exists?
  #
  #  begin
  #    file_path = @resource.filename
  #    keys = @resource.keys
  #
  #    buddycmd = "Print :%s" % keys.join(':')
  #    buddyvalue = plistbuddy(file_path, '-c', buddycmd).strip
  #
  #    # TODO: Compare the elements of the array by parsing the output from PlistBuddy
  #    # TODO: Convert desired dates into a format that can be compared by value.
  #    # TODO: Find a way of comparing Real numbers by casting to Float etc.
  #    case @resource.value_type
  #      when :array
  #        true # Assume the existence of the array even if the elements are different. Otherwise we need to parse the output
  #      when :real
  #        true # Assume the existence of the real number because the actual value will be stored differently.
  #      when :date
  #        true # Assume the existence of the date is enough. This is because the timezone will be converted upon adding the date.
  #      else
  #        @resource[:value].to_s == buddyvalue
  #    end
  #
  #  rescue Exception => e
  #    # A bad return value from plistbuddy indicates that the key does not exist.
  #    false
  #  end
  #end
end