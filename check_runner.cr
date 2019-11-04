require "toml"   # reads our TOML configuration files - see https://github.com/crystal-community/toml.cr
require "redis"    # we'll use Redis as our central backend - see https://github.com/stefanwille/crystal-redis
require "popcorn"  # we use this to simplify type conversions - see https://github.com/icyleaf/popcorn
require "json"     # we use this to convert our hashes into JSON for storing them into Redis

require "./startup_checks.cr"
require "./check_runner_functions.cr"

# setting some variables to make things look pretty
OK   = "[  OK  ]"
INFO = "[ INFO ]"
FAIL = "[ FAIL ]"
WARN = "[ WARN ]"

SETTINGS_FILE = "./settings.toml" # the settings file
CHECKS_FILE   = "./checks.toml"   # load all checks from this file
#status = Hash(String, Int32).new(0)
status = Hash(String, Hash(String, Int32)).new
##########################################################################################
# Include functions from files
##########################################################################################

# include functions from the ./startup_checks.cr file
include StartupChecks
include CheckRunnerFunctions

##########################################################################################
# Startup checks
##########################################################################################

# the check_if_settings_file_exists function is in ./startup_checks.cr
check_if_settings_file_exists(CHECKS_FILE)

puts "#{INFO} - Parsing \"#{CHECKS_FILE}\" - \"checks\" file..."
CHECKS = TOML.parse_file(CHECKS_FILE).as(Hash)

# see if we can connect to Redis - this function is in ./scheduler_checks_functions.cr
redis_host="127.0.0.1"
redis_port=Popcorn.to_int("6379")
redis_check(redis_host,redis_port)

loop do
	# get the next check from Redis and store it in the retrieved_check_in_json variable
	retrieved_check_in_json = grab_next_check_from_redis(redis_host,redis_port)
	# get the unique_name of this check and the nagios_plugin_command_string
	unique_name                  = retrieved_check_in_json["unique_name"]
	nagios_plugin_command_string = retrieved_check_in_json["nagios_plugin_command_string"]
	# print out the JSON (debugging!)
	pp retrieved_check_in_json
	# execute the check, store the output in the output variable and the exit_status in the exit_status variable
	command_output, command_exit_status = execute_check(unique_name, nagios_plugin_command_string)
	update_database_with_check_result(redis_host, redis_port, unique_name, command_output, command_exit_status)
end
