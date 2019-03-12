require "toml"   # reads our TOML configuration files - see https://github.com/crystal-community/toml.cr
require "tasker" # this helps us schedule stuff - see https://github.com/spider-gazelle/tasker
require "raze"   # we add the Raze framework so that we can handle alert acknowledgements
require "./startup_checks.cr"


# settings some variables to make things look pretty
OK   = "[  OK  ]"
INFO = "[ INFO ]"
FAIL = "[ FAIL ]"
SETTINGS_FILE = "./settings.toml"
CHECKS_FILE   = "./checks.toml"
status = Hash(String, Int32).new(0)

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

# use this function to increase the count for a check
# (add the check to the hash if not already there)
def increment_failures_by_one(status_hash,unique_name)
	status_hash[unique_name]=status_hash[unique_name]+1
end

# use this function to reset the count for a check
def reset(status_hash,unique_name)
	status_hash[unique_name]=0
end

def check_executor(status_hash,unique_name,command_string)
	puts "#{INFO} - #{Time.now} - Running check \"#{command_string}\"..."
	output      = `#{command_string}`
	exit_status = $?.exit_status
	if exit_status == 0
		reset(status_hash,unique_name)
		puts "#{OK} - #{Time.now} - Check \"#{command_string}\" result: #{exit_status} - current count: #{status_hash[unique_name]}"
	else
		increment_failures_by_one(status_hash,unique_name)
		puts "#{FAIL} - #{Time.now} - Check \"#{command_string}\" result: #{exit_status} - current count: #{status_hash[unique_name]}"
	end
#	puts "#{Time.now} - Check \"#{command_string}\" result: #{exit_status} - current count: #{status_hash[unique_name]}"

end

# create a scheduler
schedule = Tasker.instance

# go through the TOML hash and add checks to the scheduler
CHECKS.each do |host,hash_of_checks|
	puts "#{INFO} - Importing checks for \"#{host}\"..."
	checks=hash_of_checks.as(Hash)
	checks.each do |check,parameters|
		unique_name      = "#{host}_#{check}"
		description      = parameters.as(Hash)["description"]
		command_string   = parameters.as(Hash)["command_string"]
		interval_seconds = parameters.as(Hash)["interval_seconds"]

		# apply the schedule from the TOML file
		schedule.every(("#{interval_seconds}".to_i).seconds) { check_executor(status,unique_name,command_string) }
		# also if it's the first run, run them right now so we're all caught up yo
            	schedule.in(1.seconds) { check_executor(status,unique_name,command_string) } 
	end
end

Raze.config.port = 3000

post "/acknowledge" do |ctx|
	# source: https://github.com/samueleaton/raze/issues/3
	body = ctx.request.body.not_nil!.gets_to_end
	json = JSON.parse(body)
	puts json.inspect
	"#{json.inspect}"
end

Raze.run
