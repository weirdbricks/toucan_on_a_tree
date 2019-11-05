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

end
