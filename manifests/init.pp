class puppet-plist {

	notify { "Running plist testing manifest": }

	# This is a very rudimentary demonstration of the plist provider proof of concept.
	# The 'Testing' key from this plist should be forced to True
	
	$plist_content = '<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
			<key>Settings</key>
			<true/>
		</dict>
		</plist>'
	
	$settings_string = "this is a test string."

	#plist { "/tmp/test.plist":
		# This should be replaced with the same content property as the 'File' type.
	#	content => template('puppet-plist/test.plist.erb'),
	#	force => false,
	#}


    # This is another test of a plist key/value based resource type.

    plistkv { "/tmp/test.plist:keyname":
        ensure     => present,
        provider   => plistbuddy,
        value      => "testvalue",
        value_type => string,
    }
}