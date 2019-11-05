require "toml"   # reads our TOML configuration files - see https://github.com/crystal-community/toml.cr
require "tasker" # this helps us schedule stuff - see https://github.com/spider-gazelle/tasker
require "raze"   # we add the Raze framework so that we can handle alert acknowledgements
require "slack"  # we use slack to send notifications to a slack channel
require "./startup_checks.cr"

# setting some variables to make things look pretty
OK   = "[  OK  ]"
INFO = "[ INFO ]"
FAIL = "[ FAIL ]"

SETTINGS_FILE = "./settings.toml" # the settings file
CHECKS_FILE   = "./checks.toml"   # load all checks from this file
#status = Hash(String, Int32).new(0)
status = Hash(String, Hash(String, Int32)).new
##########################################################################################
# Include functions from files
##########################################################################################

# include functions from the ./startup_checks.cr file
include StartupChecks

##########################################################################################
# Startup checks
##########################################################################################

# the check_if_settings_file_exists function is in ./startup_checks.cr
check_if_settings_file_exists(CHECKS_FILE)

puts "#{INFO} - Parsing \"#{CHECKS_FILE}\" - \"checks\" file..."
CHECKS = TOML.parse_file(CHECKS_FILE).as(Hash)

def init_hash_key(status_hash,unique_name,count_to_alert_on,count_to_clear)
	unless status_hash.has_key?(unique_name)
		status_hash[unique_name]={"fail_count"      => 0,
			    		"clear_count"       => 0,
			    		"count_to_alert_on" => count_to_alert_on,
					"count_to_clear"    => count_to_clear}
	end
end

def send_slack_message(message_text,slack_channel,webhook_url)
	message = Slack::Message.new(message_text, channel: slack_channel)
	message.send_to_hook webhook_url
end

loop do
	pp status
	sleep 5
end
