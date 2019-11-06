module StartupChecks
	extend self

	# check if we can get some file 
	def check_if_file_exists(filename)
		puts "#{INFO} - Check if we can get the \"#{filename}\" file..."
		if File.file?(filename)
			puts "#{OK} - The file \"#{filename}\" exists"
		else
			puts "#{FAIL} - Sorry, I couldn't find the file \"#{filename}\"."
			exit 1
		end

	end

	# check if we can get the hostname from the local machine
	def get_hostname
		puts "#{INFO} - Check if we can get the hostname..."
		hostname=System.hostname
		if hostname.empty?
			puts "#{FAIL} - Sorry, I cannot get the hostname :("
			exit 1
		else
			puts "#{OK} - I got the hostname: \"#{hostname}\""
		end
		return hostname
	end

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

	def check_if_toml_file_is_parseable(filename)
		puts "#{INFO} - Trying to parse the file \"#{filename}\" as TOML..."
		begin
			TOML.parse_file(filename).as(Hash)
		rescue
			abort "#{FAIL} - Sorry, I could not parse the \"#{filename}\" file."
		end
		puts "#{OK} - Successfully parsed the file \"#{filename}\" as TOML"
	end

end
