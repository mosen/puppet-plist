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