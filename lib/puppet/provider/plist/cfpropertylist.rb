require 'facter/util/cfpropertylist'

Puppet::Type.type(:plist).provide :cfpropertylist, :parent => Puppet::Provider do
  desc "This provider parses and modifies the PropertyList using CFPropertyList starting from facter 2.0"

  confine :facterversion => '2.0.0'
  defaultfor :operatingsystem => :darwin
  # Not confined to darwin because CFPropertyList can work fine on other platforms.

  def self.value_for_key(hash, keys)

    val = hash

    begin
      keys.each do |key|
        if val.has_key? key
          val = val[key]
        else
          raise 'Key not found in plist hash'
        end
      end

      val
    rescue Exception => e
      nil
    end
  end

  def create
    file_path = @resource.filename
    keys = @resource.keys

    if File.exists? file_path
      begin
        debug("Reading existing Plist at #{file_path}")
        plist = Facter::Util::CFPropertyList::List.new(:file => file_path)
        #plist_content = Facter::Util::CFPropertyList.native_types(plist.value)
      rescue Exception => e
        debug("Got exception trying to read Plist file: #{e}")
      end
    else
      debug("Plist file does not exist, creating new Plist...")
      plist = Facter::Util::CFPropertyList::List.new
      plist_content = Hash.new
    end

    hash_to_modify = plist_content
    value_key = keys.pop

    #debug('Path to Plist parent key: ' + keys.join(':'))
    #debug('Plist key: ' + value_key)

    keys.each do |key|
      if hash_to_modify.has_key? key
        hash_to_modify = hash_to_modify[key]
      else
        child = Hash.new
        hash_to_modify[key] = child
        hash_to_modify = child
      end
    end

    hash_to_modify[value_key] = @resource[:value]

    #debug('New structure: ' + plist_content.inspect)

    plist.value = Facter::Util::CFPropertyList.guess(plist_content)
    plist.save(file_path, Facter::Util::CFPropertyList::List::FORMAT_XML)
  end

  #
  #def destroy
  #  elements = @resource[:name].split(/[^\\]:/)
  #  file_path = elements.pop
  #
  #  begin
  #    raise "Does not exist" if !File.exists?(file_path)
  #    raise "File is unreadable" if !File.readable?(file_path)
  #
  #    plist_file = CFPropertyList::List.new(:file => file_path)
  #    native_values = CFPropertyList.native_types(plist_file.value)
  #
  #    containing_hash = self.class.keypath(native_values, elements)
  #
  #    if containing_hash == nil
  #      raise "The specified key does not exist in the plist dictionary."
  #    else
  #      containing_hash.delete elements[elements.count - 1]
  #      # TODO: save resulting hash to plist
  #    end
  #  rescue
  #    puts "Failed to destroy"
  #  end
  #end
  #
  def exists?
    file_path = @resource.filename
    keys = @resource.keys

    begin
      raise "Does not exist" if !File.exists?(file_path)
      raise "File is unreadable" if !File.readable?(file_path)

      plist_file = Facter::Util::CFPropertyList::List.new(:file => file_path)
      plist_native = Facter::Util::CFPropertyList.native_types(plist_file.value)

      value = self.class.value_for_key(plist_native, keys)

      if value == nil || value != @resource[:value]
        false
      else
        true
      end
    rescue
      false
    end

  end
end