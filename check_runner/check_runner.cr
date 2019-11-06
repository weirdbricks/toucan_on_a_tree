##########################################################################################
# Include functions from files
##########################################################################################

require "../startup.cr"
include Startup
require "./check_runner_functions.cr"

# include functions from the ./check_runner/check_runner_functions.cr file
include CheckRunnerFunctions

##########################################################################################
# Execute checks
##########################################################################################

loop do
	# get the next check from Redis and store it in the retrieved_check_in_json variable
	retrieved_check_in_json = grab_next_check_from_redis(REDIS_HOST,REDIS_PORT)
	# get the unique_name of this check and the nagios_plugin_command_string
	unique_name                  = retrieved_check_in_json["unique_name"]
	nagios_plugin_command_string = retrieved_check_in_json["nagios_plugin_command_string"]
	# print out the JSON (debugging!)
	pp retrieved_check_in_json
	# execute the check, store the output in the output variable and the exit_status in the exit_status variable
	command_output, command_exit_status = execute_check(unique_name, nagios_plugin_command_string)
	update_database_with_check_result(REDIS_HOST, REDIS_PORT, unique_name, command_output, command_exit_status)
end
