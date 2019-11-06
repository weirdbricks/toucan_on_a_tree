require "tasker"   # this helps us schedule stuff - see https://github.com/spider-gazelle/tasker

##########################################################################################
# Include functions from files
##########################################################################################

require "../startup.cr"
include Startup
require "./scheduler_checks_functions.cr"
CHECKS_FILE = "./checks.toml"   # load all checks from this file

include SchedulerRedis

##########################################################################################
# Startup checks
##########################################################################################

# the check_if_file_exists function is in ../startup_checks.cr
check_if_file_exists(CHECKS_FILE)

# see if we can parse the TOML files - this function is in ./startup_checks.cr
check_if_toml_file_is_parseable(CHECKS_FILE)
CHECKS   = TOML.parse_file(CHECKS_FILE).as(Hash)

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

		# create a hash out of the details we got
		scheduled_check_hash = {
			unique_name:                  "#{host}_#{check}",
			description:                  parameters.as(Hash)["description"],
			nagios_plugin_command_string: parameters.as(Hash)["command_string"],
			interval_seconds:             Popcorn.to_int(parameters.as(Hash)["interval_seconds"]),
			count_to_alert_on:            Popcorn.to_int(parameters.as(Hash)["count_to_alert_on"]), #ugly, but it was the only way I could find to cast it to the right type
			count_to_clear:               Popcorn.to_int(parameters.as(Hash)["count_to_clear"]) #ugly, but it was the only way I could find to cast it to the right type
		}

		unique_name      = scheduled_check_hash["unique_name"]
		interval_seconds = scheduled_check_hash["interval_seconds"]

		# convert the hash to json so we can push it into redis
		jsonized_check = scheduled_check_hash.to_json

		# apply the schedule from the TOML file		
		schedule.every(interval_seconds.seconds) {
		number_of_checks=get_number_of_checks_from_redis_for_a_unique_name(REDIS_HOST, REDIS_PORT, unique_name)
		if number_of_checks >= 10
			puts "#{WARN} - The number of scheduled checks for \"#{unique_name}\" is too high - I'm not going to schedule an additional test!"
			next
			end
			puts "#{INFO} - Queueing check \"#{unique_name}\" - Interval seconds: #{interval_seconds} ..."
			queue_a_check_in_redis(REDIS_HOST, REDIS_PORT,jsonized_check)
		}

		# also if it's the first run, run them right now so we're all caught up yo
		schedule.in(0.seconds) {
			number_of_checks=get_number_of_checks_from_redis_for_a_unique_name(REDIS_HOST, REDIS_PORT, unique_name)
			if number_of_checks >= 10 
				puts "#{WARN} - The number of scheduled checks for \"#{unique_name}\" is too high - I'm not going to schedule an additional test!"
				next
			end
			puts "#{INFO} - Queueing check \"#{unique_name}\" (Initial Check) seconds ..."
			queue_a_check_in_redis(REDIS_HOST, REDIS_PORT, jsonized_check)
		}

	end
end

loop do
	# we use this loop to keep the scheduler alive ;)
	sleep 10
end
