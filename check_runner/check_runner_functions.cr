module CheckRunnerFunctions 
	extend self

	# check if we can connect to redis
	def redis_check(redis_host,redis_port)
		puts "#{INFO} - Attempting to connect to Redis at: #{redis_host}:#{redis_port}..."
		begin
			redis = Redis.new(host: redis_host, port: redis_port)
		rescue
			abort "#{FAIL} - I cannot connect to Redis at: #{redis_host}:#{redis_port} - Is Redis running?"
		end
		puts "#{OK} - Successfully connected to Redis!"
	end

	def grab_next_check_from_redis(redis_host, redis_port)
		# open connection to redis
                redis = Redis.new(host: redis_host, port: redis_port)
		puts "#{INFO} - Getting the next check from the list..."
		check_from_redis=redis.lpop("check_queue")
		while check_from_redis.nil?
			puts "#{WARN} - #{Time.local} - No queued check found - sleeping for 3 seconds"
			sleep 3
			check_from_redis=redis.lpop("check_queue")
		end	
		check_from_redis_json = JSON.parse(check_from_redis.to_s)
		return check_from_redis_json
		redis.quit
	end

	# this function takes a unique_name and a nagios_plugin_command_string and executes it
	# the output is the command output plus the exit_status
	def execute_check(unique_name, nagios_plugin_command_string)
		puts "#{INFO} - #{Time.local} - Unique Name: \"#{unique_name}\" - Running check \"#{nagios_plugin_command_string}\"..."
		command_output      = `#{nagios_plugin_command_string}`
		command_exit_status = $?.exit_status
		
		return command_output, command_exit_status
	end

	def update_database_with_check_result(redis_host,redis_port,unique_name,command_output,command_exit_status)
		# open connection to redis
                redis = Redis.new(host: redis_host, port: redis_port)
		puts "#{INFO} - Updating Redis for Check: \"#{unique_name}\"..."
		if command_exit_status == 0
			redis.hset(unique_name, "failure_count", 0)
			puts "#{OK} - #{Time.local} - Successfully updated Redis for Check \"#{unique_name}\" - Command exit code: #{command_exit_status} - Resetting fail count to 0"
		else
			current_fail_count=redis.hincrby(unique_name, "failure_count", 1)
			puts "#{OK} - #{Time.local} - Successfully updated Redis for Check \"#{unique_name}\" - Command exit code: #{command_exit_status} - current count: #{current_fail_count}"
		end
		redis.quit
	end


end
