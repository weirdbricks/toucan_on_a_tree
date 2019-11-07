require "tasker"   # this helps us schedule stuff - see https://github.com/spider-gazelle/tasker

##########################################################################################
# Include functions from files
##########################################################################################

require "./startup.cr"
include Startup
#require "./scheduler_checks_functions.cr"
#### not sure if needed??? ### CHECKS_FILE = "./checks.toml"   # load all checks from this file

#include SchedulerRedis

##########################################################################################
# Startup checks
##########################################################################################

#####puts "#{INFO} - Parsing \"#{CHECKS_FILE}\" - \"checks\" file..."
#### not sure if needed??? ### CHECKS = TOML.parse_file(CHECKS_FILE).as(Hash)

#def init_hash_key(status_hash,unique_name,count_to_alert_on,count_to_clear)
#	unless status_hash.has_key?(unique_name)
#		status_hash[unique_name]={"fail_count"      => 0,
#			    		"clear_count"       => 0,
#			    		"count_to_alert_on" => count_to_alert_on,
#					"count_to_clear"    => count_to_clear}
#	end
#end

def send_slack_message(message_text,slack_channel,webhook_url)
	message = Slack::Message.new(message_text, channel: slack_channel)
	message.send_to_hook webhook_url
end

def get_all_keys_from_redis(redis_host,redis_port)
	# open connection to redis
	redis = Redis.new(host: redis_host, port: redis_port)
	redis_result_array=redis.keys("*")
	# we ignore the "check_queue" key :)
	redis_result_array.reject!("check_queue")
	redis.quit
	return redis_result_array
end

def get_redis_value_for_key(redis_host,redis_port,key)
###                         redis.hset(unique_name, "failure_count", 0)

	# open connection to redis
	redis = Redis.new(host: redis_host, port: redis_port)
	failure_count = redis.hget(key,"failure_count")
	redis.quit
	return failure_count
end

redis_keys_array=get_all_keys_from_redis(REDIS_HOST, REDIS_PORT)
redis_keys_array.each do |redis_key|
	value=get_redis_value_for_key(REDIS_HOST, REDIS_PORT, redis_key)
	puts "key: #{redis_key} , value: #{value}"
end

#loop do
#	pp status
#	sleep 5
#end
