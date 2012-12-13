require 'date'

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
              when :real # The type will generally compare vs a stringified version, caution: dirty hacks
                prefetched_values[:value] = print_value.to_f.to_s
              when :date
                prefetched_values[:value] = Date.parse(print_value).strftime('%Y-%m-%d')
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
    value_type = @property_hash[:value_type]

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
              fail('The value supplied was not an array') unless @property_hash[:value].kind_of?(Array)

              # Add the array entry
              #buddy_cmd << "%s" % [  ]

              # Add the elements
              @property_hash[:value].each do |value|
                plistbuddy(file_path, '-c', buddy_cmd)
                buddy_cmd = "Add :%s:0 %s %s" % [ keys.join(':'), 'string', value ]
              end

              #fail('The Plistbuddy provider does not support structured values.')
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

          plistbuddy(file_path, '-c', buddy_cmd)

        rescue Exception => e
          debug(e.message)
          false
        end
    end

    @property_hash.clear
  end

end