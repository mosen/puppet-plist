Puppet::Type.type(:plist).provide :cfpropertylist, :parent => Puppet::Provider do
  desc "This provider parses and modifies the PropertyList using CFPropertyList starting from facter 2.0"

  confine :facterversion => '2.0.0' # CFPropertyList is bundled with facter 2
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
    require 'facter/util/cfpropertylist'

    file_path = @resource.filename
    keys = @resource.keys

    if File.exists? file_path
      begin
        debug("Reading existing Plist at #{file_path}")
        plist = Facter::Util::CFPropertyList::List.new(:file => file_path)
        plist_content = Facter::Util::CFPropertyList.native_types(plist.value)
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

    hash_to_modify[value_key] = case @resource.value_type
      when :integer then @resource[:value].to_i
      when :real then @resource[:value].to_f
      when :date then Date.parse(@resource[:value])
      else @resource[:value]
    end

    #debug('New structure: ' + plist_content.inspect)

    plist.value = Facter::Util::CFPropertyList.guess(plist_content)
    plist.save(file_path, Facter::Util::CFPropertyList::List::FORMAT_XML)
  end


  # TODO: DRY
  def destroy
    require 'facter/util/cfpropertylist'

    file_path = @resource.filename
    keys = @resource.keys

    begin
      debug("Reading existing Plist at #{file_path}")
      plist = Facter::Util::CFPropertyList::List.new(:file => file_path)
      plist_content = Facter::Util::CFPropertyList.native_types(plist.value)
    rescue Exception => e
      raise "Got exception trying to read Plist file: #{e}"
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

    hash_to_modify.delete(value_key)

    #debug('New structure: ' + plist_content.inspect)

    plist.value = Facter::Util::CFPropertyList.guess(plist_content)
    plist.save(file_path, Facter::Util::CFPropertyList::List::FORMAT_XML)
  end

  def exists?
    require 'facter/util/cfpropertylist'

    file_path = @resource.filename
    keys = @resource.keys

    begin
      raise "File does not exist" if !File.exists?(file_path)
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