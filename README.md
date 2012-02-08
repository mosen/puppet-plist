Puppet Plist Resource Type
==========================

This is an in-progress proof of concept for a plist resource type in puppet.

Design
------

Puppet requires one variable to be established as the unique identifier. For this we use
the path and filename of the plist to modify, rather than an abstract of name and key/path to key.

For the plist provider we establish a behaviour similar to MCX.
The content or source file is merged with the target file in one of two ways, having a similar effect as the MCX
Always and Once policies.

The content of the plist file is specified as an .erb template, which suits dynamic subsitution of values, or we can use
a static file.

The two plist resource policies are `defaults` and `enforced`.

`defaults` means that the contents of the template are merged into the target plist, only if the keys don't exist in the
target.

`enforced` means that keys that do exist already in the target plist, are overwritten.

In any case, if the keys don't exist in the target they are set based on the template (source) plist.

Caveats
-------

Two puppet modules cannot manage the same resource, at the file level.

Future solution: allow the plist resource to specify a key path to start managing from (subtree management).

Example
-------

```

    class plist_test {

        notify { "Running plist testing manifest": }

        # This is a very rudimentary demonstration of the plist provider proof of concept.
        # The 'Testing' key from this plist should be forced to True

        $plist_content = '<?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Testing</key>
                <true/>
            </dict>
            </plist>'


        plist { "/tmp/test.plist":
            # This should be replaced with the same content property as the 'File' type.
            content => $plist_content,
            merge => enforced,
        }
    }

    node default {
	    include plist_test
    }
```

