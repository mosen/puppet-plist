Puppet::Type.type(:plist).provide :plistbuddy, :parent => Puppet::Provider do

  desc "This provider alters plist values using the PlistBuddy(8) command line utility.

  Because of the way that PlistBuddy deals with types, it cannot convert an existing Plist key from one type to another.
  The key must first be removed in order to change the type of value it contains.
  "

  commands :plistbuddy => "/usr/libexec/PlistBuddy"
  confine :operatingsystem => :darwin

  def create
      begin
        file_path = @resource.filename
        keys = @resource.keys
        value_type = @resource.value_type

        if value_type == :array

          # Add the array entry
          buddycmd = "Add :%s %s %s" % [ keys.join(':'), value_type, @resource[:value] ]

          # Add the elements
          @resource[:value].each do |value|
            plistbuddy(file_path, '-c', buddycmd)
            buddycmd = "Add :%s:0 %s %s" % [ keys.join(':'), 'string', value ]
          end
        elsif value_type == :date
          native_date = Date.parse(@resource[:value])
          buddycmd = "Add :%s %s %s" % [ keys.join(':'), value_type,  native_date.strftime('%a %b %e %H:%M:%S %Z %Y')]
        else
          buddycmd = "Add :%s %s %s" % [ keys.join(':'), value_type, @resource[:value] ]
        end

        plistbuddy(file_path, '-c', buddycmd)

      rescue Exception => e
        false
      end
  end

  def destroy
    begin
      file_path = @resource.filename
      keys = @resource.keys

      buddycmd = "Delete :%s" % keys.join(':')
      plistbuddy(file_path, '-c', buddycmd)
    rescue Exception => e
      false
    end
  end

  def exists?

    begin
      file_path = @resource.filename
      keys = @resource.keys

      buddycmd = "Print :%s" % keys.join(':')
      buddyvalue = plistbuddy(file_path, '-c', buddycmd).strip

      # TODO: Not doing any type checking
      # TODO: Arrays and Real Numbers are not correctly value compared (Arrays dont get parsed from PlistBuddy output,
      # and real numbers dont have the same decimal representation internally)
      @resource[:value].to_s == buddyvalue
    rescue Exception => e
      # A bad return value from plistbuddy indicates that the key does not exist.
      false
    end
  end
end