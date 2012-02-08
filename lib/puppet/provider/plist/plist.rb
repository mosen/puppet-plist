# TODO: consider Puppet.Features.add :plist, lib => cfpropertylist. Can user submitted providers do this?

require 'facter/util/cfpropertylist'

Puppet::Type.type(:plist).provide :plist, :parent => Puppet::Provider do
  desc "
    This provider merges plist files into other plist files, based upon a set
    of rules set by the plist type.
    
    It relies on the CFPropertyList class to parse and generate plist files.
  "
  
  include Puppet::Util::Warnings

  defaultfor :operatingsystem => :darwin
  has_feature :plist # TODO: check feature availability via lib detection of CFPropertyList

  # no confine method defined here because our target platform might not be darwin (eg. plist configuration on linux).

  # Generate the difference between the supplied source plist and the target.
  # This is used to determine whether the resource should be updated or not, so in the case that the target plist
  # contains different keys, but all of the SPECIFIED keys are equal, the content should return the same thing
  # TODO: maybe override insync? or something similar
  def content
    puts 'Getting content'
    # Iterate through target to find keys and values matching the content
    # Return the current values for those keys and values
    plist_diff_hash = self.plist_diff(self.read_plist(@resource[:path]), self.read_plist_string(@resource[:content]))
  end

  # Set the plist content to use for merging into the target.
  def content= (value)
  end

  # Read the plist string into Ruby native values.
  def self.read_plist_string(value)
    plist_data = CFPropertyList::List.new(:data => value)
    native_values = CFPropertyList.native_types(plist_data.value)

    native_values
  end

  # Read the plist file into Ruby native values.
  def self.read_plist(path)
    plist_file = CFPropertyList::List.new(:file => path)
    native_values = CFPropertyList.native_types(plist_file.value)

    native_values
  end
  
  def self.plist_diff(plist_a, plist_b)
    log('Diffing plists');
  end
end