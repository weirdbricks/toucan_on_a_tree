module SchedulerRedis 
	extend self

	def queue_a_check_in_redis(redis_host,redis_port,jsonized_check) 
		# open connection to redis
                redis = Redis.new(host: redis_host, port: redis_port)

               # push (append) the hash to our redis list "check_queue"
                redis.rpush("check_queue",jsonized_check)
#                # print out the current length of the queue
#                puts redis.llen("check_queue")
                # close the connection to redis
                redis.quit

	end

	def get_number_of_checks_from_redis_for_a_unique_name(redis_host,redis_port,unique_name)
		# open connection to redis
                redis = Redis.new(host: redis_host, port: redis_port)
		counter=0 # just a counter to figure out how many items we have with the same unique_name
		redis.lrange("check_queue", 0, -1).each do |item|
			item_json = JSON.parse(item.to_s)
			# skip the item if it's not the same as our passed unique_name
			next if item_json["unique_name"] != unique_name
			counter=counter+1
		end
		puts "#{INFO} - Found \"#{counter}\" items with unique_name: \"#{unique_name}\""
		return counter
		redis.quit
	end

end
