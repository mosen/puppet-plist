## puppet-plist module

## User Guide

### Overview

This type provides the ability to manage property list (binary and xml) files.

Limitations:
+ If you don't have facter v2, you can only use a subset of the functionality.
+ The basic plist type only covers basic, single value changes. Structured types are very limited.
+ It's beta at the moment

### Installation

This module provides new types in the form of plugins, so pluginsync must be enabled for every agent in the
puppet configuration (usually /etc/puppet/puppet.conf) like this:

    [agent]
    pluginsync = true

Without pluginsync enabled, any manifest with a `plist` resource in it will throw an error
or possibly just do nothing.

### Examples

#### Basic



### Bugs

Please submit any issues through Github issues as I don't have a dedicated project page for this module.

### Contributing

You can issue a pull request and send me a message if you like, and I will consider taking the patch upstream :)
See the file DEVELOPER.md for information about the roadmap and features.

### Testing

They really don't exist. It's a proof of concept.

### Notes

+ In 10.8 and later, preferences are synchronised by `cfprefsd` and changing the .plist file associated with a service
may not take any effect at all. Apple recommends use of native API or the `defaults` command.
[https://developer.apple.com/library/mac/#releasenotes/CoreFoundation/CoreFoundation.html]