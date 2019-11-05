require "toml"     # reads our TOML configuration files - see https://github.com/crystal-community/toml.cr
require "tasker"   # this helps us schedule stuff - see https://github.com/spider-gazelle/tasker
require "redis"    # we'll use Redis as our central backend - see https://github.com/stefanwille/crystal-redis
require "popcorn"  # we use this to simplify type conversions - see https://github.com/icyleaf/popcorn
require "json"     # we use this to convert our hashes into JSON for storing them into Redis

require "../startup_checks.cr"
require "./scheduler_checks_functions.cr"

# setting some variables to make things look pretty
OK   = "[  OK  ]"
INFO = "[ INFO ]"
FAIL = "[ FAIL ]"
WARN = "[ WARN ]"

SETTINGS_FILE = "./settings.toml" # the settings file
CHECKS_FILE   = "./checks.toml"   # load all checks from this file

##########################################################################################
# Include functions from files
##########################################################################################

# include functions from the ./startup_checks.cr file
include StartupChecks
include SchedulerRedis

##########################################################################################
# Startup checks
##########################################################################################

# the check_if_file_exists function is in ../startup_checks.cr
check_if_file_exists(SETTINGS_FILE)
check_if_file_exists(CHECKS_FILE)

puts "#{INFO} - Parsing \"#{CHECKS_FILE}\" - \"checks\" file..."
CHECKS = TOML.parse_file(CHECKS_FILE).as(Hash)

# see if we can connect to Redis - this function is in ./scheduler_checks_functions.cr
redis_host="127.0.0.1"
redis_port=Popcorn.to_int("6379")
redis_check(redis_host,redis_port)

##########################################################################################
# Schedule checks 
##########################################################################################

# create a scheduler
schedule = Tasker.instance

max_counter=CHECKS.keys.size   # the total number of checks found in the file
counter=0                      # a counter used to display how many checks we've imported

# go through the TOML hash and add checks to the scheduler
CHECKS.each do |host,hash_of_checks|
	counter=counter+1
	puts "#{INFO} - Host: #{counter}/#{max_counter} - Importing checks for \"#{host}\"..."
	checks=hash_of_checks.as(Hash)
	max_number_of_checks=checks.keys.size
	number_of_checks=0
	checks.each do |check,parameters|
		number_of_checks=number_of_checks+1
		puts "#{INFO} - Importing check #{number_of_checks}/#{max_number_of_checks}"
		unique_name                  = "#{host}_#{check}"
		description                  = parameters.as(Hash)["description"]
		nagios_plugin_command_string = parameters.as(Hash)["command_string"]
		interval_seconds             = parameters.as(Hash)["interval_seconds"]
		count_to_alert_on            = parameters.as(Hash)["count_to_alert_on"].to_s.to_i32 #ugly, but it was the only way I could find to cast it to the right type
		count_to_clear               = parameters.as(Hash)["count_to_clear"].to_s.to_i32 #ugly, but it was the only way I could find to cast it to the right type

                # create a hash out of the details we got
                scheduled_check_hash = {
                        unique_name: unique_name,
                        description: description,
                        nagios_plugin_command_string: nagios_plugin_command_string,
                        interval_seconds: interval_seconds,
                        count_to_alert_on: count_to_alert_on,
                        count_to_clear: count_to_clear
                }

		# convert the hash to json so we can push it into redis
		jsonized_check = scheduled_check_hash.to_json

                # apply the schedule from the TOML file		
		schedule.every(("#{interval_seconds}".to_i).seconds) {
                        number_of_checks=get_number_of_checks_from_redis_for_a_unique_name(redis_host,redis_port,unique_name)
                        if number_of_checks >= 10
                                puts "#{WARN} - The number of scheduled checks for \"#{unique_name}\" is too high - I'm not going to schedule an additional test!"
				next
			end
			puts "#{INFO} - Queueing check \"#{unique_name}\" - Interval seconds: #{interval_seconds} ..."
			queue_a_check_in_redis(redis_host,redis_port,jsonized_check)
		}

		# also if it's the first run, run them right now so we're all caught up yo
		schedule.in(0.seconds) {
			number_of_checks=get_number_of_checks_from_redis_for_a_unique_name(redis_host,redis_port,unique_name)
			if number_of_checks >= 10 
				puts "#{WARN} - The number of scheduled checks for \"#{unique_name}\" is too high - I'm not going to schedule an additional test!"
				next
			end
			puts "#{INFO} - Queueing check \"#{unique_name}\" (Initial Check) seconds ..."
			queue_a_check_in_redis(redis_host,redis_port,jsonized_check)
		}

	end
end

loop do
	# we use this loop to keep the scheduler alive ;)
	sleep 10
end
