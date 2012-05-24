Puppet::Type.type(:plistkv).provide :plistbuddy, :parent => Puppet::Provider do
  desc "This provider alters plist values using the PlistBuddy(8) command line utility."

  commands :plistbuddy => "/usr/libexec/PlistBuddy"
  confine :operatingsystem => :darwin
  defaultfor :operatingsystem => :darwin

  def create
      begin
        elements = @resource[:path].split(/:/) # TODO: test for filenames which have escaped colon characters (this should be an outside case)
        file_path = elements.shift

        buddycmd = "Add :%s string %s" % [ elements.join(':'), @resource[:value] ]
        plistbuddy(file_path, '-c', buddycmd)
      rescue Exception => e
        puts e.message
        false
      end
  end

  def destroy
    begin
      elements = @resource[:path].split(/:/) # TODO: test for filenames which have escaped colon characters (this should be an outside case)
      file_path = elements.shift

      buddycmd = "Delete :%s" % elements.join(':')
      plistbuddy(file_path, '-c', buddycmd)
    rescue Exception => e
      puts e.message
      false
    end
  end

  def exists?

    begin
      elements = @resource[:path].split(/:/) # TODO: test for filenames which have escaped colon characters (this should be an outside case)
      file_path = elements.shift

      buddycmd = "Print :%s" % elements.join(':')

      # TODO: Not doing any type checking
      @resource[:value] == plistbuddy(file_path, '-c', buddycmd)
    rescue Exception => e
      puts e.message
      # Command execution returns non-zero status
      false
    end
  end
end