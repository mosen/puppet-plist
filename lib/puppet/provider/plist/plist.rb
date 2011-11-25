require 'facter/util/cfpropertylist'
Puppet::Type.type(:plist).provide :plist, :parent => Puppet::Provider do
  desc <<-EOT
    This provider merges plist files into other plist files, based upon a set
    of rules set by the plist type.
    
    It relies on the CFPropertyList class to parse and generate plist files.
    
  EOT
  
  include Puppet::Util::Warnings

  defaultfor :operatingsystem => :darwin
  # Do not confine to darwin, there do exist plist configuration files on linux, although they are rare.

  def content
    puts 'Getting content'
    # Iterate through target to find keys and values matching the content
    # Return the current values for those keys and values
    plist_diff_hash = self.plist_diff(self.read_plist(@resource[:path]), self.read_plist_string(@resource[:content]))
  end
  
  def content= (value)
    puts 'Setting content'
  end

  # Read a plist from a string var.
  def self.read_plist_string(value)
    plist_data = CFPropertyList::List.new(:data => value)
  end

  # Read a plist, whether its format is XML or in Apple's "binary1"
  # format.
  def self.read_plist(path)
    plist_file = CFPropertyList::List.new(:file => path)
    plist_data = CFPropertyList.native_types(plist_file.value)
  end
  
  def self.plist_diff(plist_a, plist_b)
    log('Diffing plists');
  end
end