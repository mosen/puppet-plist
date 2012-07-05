Puppet::Type.type(:plist).provide :plistbuddy, :parent => Puppet::Provider do

  desc "This provider alters plist values using the PlistBuddy(8) command line utility.

  Because of the way that PlistBuddy deals with types, it cannot convert an existing Plist key from one type to another.
  The key must first be removed in order to change the type of value it contains.
  "

  commands :plistbuddy => "/usr/libexec/PlistBuddy"
  confine :operatingsystem => :darwin
  defaultfor :operatingsystem => :darwin

  def create
      begin
        file_path = @resource.filename
        keys = @resource.keys
        value_type = @resource.value_type

        if value_type == :array

          # Add the array entry
          buddycmd = "Add :%s %s %s" % [ keys.join(':'), value_type, @resource[:value] ]
          plistbuddy(file_path, '-c', buddycmd)

          # Add the elements
          @resource[:value].each do |value|
            buddycmd = "Add :%s:0 %s %s" % [ keys.join(':'), 'string', value ]
            plistbuddy(file_path, '-c', buddycmd)
          end
        else
          buddycmd = "Add :%s %s %s" % [ keys.join(':'), value_type, @resource[:value] ]
          plistbuddy(file_path, '-c', buddycmd)
        end

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

      # TODO: Not doing any type checking
      @resource[:value] == plistbuddy(file_path, '-c', buddycmd)
    rescue Exception => e
      false
    end
  end
end