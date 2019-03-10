require "tasker" # this helps us schedule stuff - see https://github.com/spider-gazelle/tasker

# settings some variables to make things look pretty
OK   = "[  OK  ]"
INFO = "[ INFO ]"
FAIL = "[ FAIL ]"
SETTINGS_FILE = "./settings.toml"

##########################################################################################
# Include functions from files
##########################################################################################

# include functions from the ./startup_checks.cr file
#include StartupChecks

# include functions from the ./docker_logs_startup_checks.cr file
#include DockerLogsStartupChecks

# include functions from the ./functions_docker.cr file
#include FunctionsDocker

# include functions from the ./functions_database.cr file
#include FunctionsDatabase

##########################################################################################
# Startup checks
##########################################################################################

def check_executor(command_string)
	output=`#{command_string}`
#	puts `#{command_string}`
#	puts "Exit code: #{$?.exit_status}"
	#puts output
	return $?.exit_status
end

# create a scheduler
schedule = Tasker.instance
schedule.every(5.seconds) { check_executor("/usr/lib/nagios/plugins/check_http -H www.google.com -t10 -c5") }
#task = schedule.every(5.seconds) { check_executor("/usr/lib/nagios/plugins/check_http -H www.bing.com -t10 -c5") }

#puts task.get


# loop forever! (but pause every second so we don't kill the cpu)
while true
	puts "one sec has passed"
	sleep 1
end
