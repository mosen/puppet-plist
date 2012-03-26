require 'facter/util/cfpropertylist' # TODO: ruby-libxml not always available

Puppet::Type.type(:plistkv).provide :plist, :parent => Puppet::Provider do
  desc "
    This provider modifies a given plist key to the specified value by parsing the entire plist, modifying the value and
    saving the plist file again.
  "

  defaultfor :operatingsystem => :darwin

  has_feature :plist

  # Find a value given an array of keys
  def self.keypath_value(hash, keys)
    key = keys.pop

    if hash.has_key?(key)
      if hash[key].is_a? Hash
        self.keypath_value(hash[key], keys)
      else
        hash[key]
      end
    else
      nil
    end
  end

  # Find the hash that the specified key path "belongs" to
  def self.keypath(hash, keys)
    key = keys.pop

    if hash.has_key?(key)
      if hash[key].is_a? Hash
        self.keypath(hash[key], keys)
      else
        hash
      end
    else
      nil
    end
  end


  def create

  end

  def destroy
    elements = @resource[:name].split(/[^\\]:/)
    file_path = elements.pop

    begin
      raise "Does not exist" if !File.exists?(file_path)
      raise "File is unreadable" if !File.readable?(file_path)

      plist_file = CFPropertyList::List.new(:file => file_path)
      native_values = CFPropertyList.native_types(plist_file.value)

      containing_hash = self.class.keypath(native_values, elements)

      if containing_hash == nil
        raise "The specified key does not exist in the plist dictionary."
      else
        containing_hash.delete elements[elements.count - 1]
        # TODO: save resulting hash to plist
      end
    rescue
      puts "Failed to destroy"
    end
  end

  def exists?
    elements = @resource[:name].split(/[^\\]:/)
    file_path = elements.pop

    begin
      raise "Does not exist" if !File.exists?(file_path)
      raise "File is unreadable" if !File.readable?(file_path)

      plist_file = CFPropertyList::List.new(:file => file_path)
      native_values = CFPropertyList.native_types(plist_file.value)

      plist_value = self.class.keypath_value(native_values, elements)

      if plist_value == nil
        false
      else
        true
      end
    rescue
      false
    end

  end
end