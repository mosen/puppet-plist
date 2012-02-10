# TODO: consider Puppet.Features.add :plist, lib => cfpropertylist. Can user submitted providers do this?


require 'facter/util/cfpropertylist' # TODO: ruby-libxml not always available

# Uses the excellent ruby hash diff methods at http://stackoverflow.com/questions/1766741/comparing-ruby-hashes
class Hash

  def diff(other)
    (self.keys + other.keys).uniq.inject({}) do |memo, key|
      unless self[key] == other[key]
        if self[key].kind_of?(Hash) &&  other[key].kind_of?(Hash)
          memo[key] = self[key].diff(other[key])
        else
          memo[key] = [self[key], other[key]]
        end
      end
      memo
    end
  end

  def apply_diff!(changes, direction = :right)
    path = [[self, changes]]
    pos, local_changes = path.pop
    while local_changes
      local_changes.each_pair {|key, change|
        if change.kind_of?(Array)
          pos[key] = (direction == :right) ? change[1] : change[0]
        else
          path.push([pos[key], change])
        end
      }
      pos, local_changes = path.pop
    end
    self
  end

  def apply_diff(changes, direction = :right)
    cloned = self.clone
    path = [[cloned, changes]]
    pos, local_changes = path.pop
    while local_changes
      local_changes.each_pair {|key, change|
        if change.kind_of?(Array)
          pos[key] = (direction == :right) ? change[1] : change[0]
        else
          pos[key] = pos[key].clone
          path.push([pos[key], change])
        end
      }
      pos, local_changes = path.pop
    end
    cloned
  end
end


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
  
  def self.plist_diff(target, settings)
     target.diff(settings)
  end

  # Generate the difference between the supplied source plist and the target.
  # This is used to determine whether the resource should be updated or not, so in the case that the target plist
  # contains different keys, but all of the SPECIFIED keys are equal, the content should return the same thing
  # TODO: maybe override insync? or something similar
  def content

    begin
      target_plist = self.class.read_plist(@resource[:path])
    rescue
      target_plist = {}
    end

    target_plist

    #
    #
    ## Iterate through target to find keys and values matching the content
    ## Return the current values for those keys and values
    #
    #plist_differences = self.class.plist_diff(target_plist, settings_plist)
    #settings_applied = target_plist.apply_diff(plist_differences)
    #
    #puts settings_applied.inspect
  end

  # Set the plist content to use for merging into the target.
  def content= (value)
    begin
      target_plist = self.class.read_plist(@resource[:path])
      target_hash = CFPropertyList.native_types(target_plist.value)
    rescue
      target_hash = {}
    end

    # Iterate through target to find keys and values matching the content
    # Return the current values for those keys and values

    settings_plist = self.class.read_plist_string(value)
    plist_differences = self.class.plist_diff(target_hash, settings_plist)
    puts plist_differences.inspect

    settings_applied = target_plist.apply_diff(plist_differences)
    puts settings_applied.inspect

    plist_applied = CFPropertyList::List.new
    plist_applied.value = CFPropertyList.guess(settings_applied)

    plist_applied.save(@resource[:path], CFPropertyList::List::FORMAT_XML)

  end
end