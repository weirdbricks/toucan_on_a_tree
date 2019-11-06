require "./startup_checks.cr"

module Startup
	extend self

	SETTINGS_FILE = "./settings.toml" # the settings file

	# setting some variables to make things look pretty
	OK   = "[  OK  ]"
	INFO = "[ INFO ]"
	FAIL = "[ FAIL ]"
	WARN = "[ WARN ]"

	include StartupChecks
	# the check_if_file_exists function is in ../startup_checks.cr
	check_if_file_exists(SETTINGS_FILE)

	# see if we can parse the TOML files - this function is in ./startup_checks.cr
	check_if_toml_file_is_parseable(SETTINGS_FILE)
	SETTINGS = TOML.parse_file(SETTINGS_FILE).as(Hash)

	REDIS_HOST = Popcorn.to_string(SETTINGS["redis_settings"].as(Hash)["redis_host"])
	REDIS_PORT = Popcorn.to_int(SETTINGS["redis_settings"].as(Hash)["redis_port"])

	# see if we can connect to Redis - this function is in ./startup_checks.cr
	redis_check(REDIS_HOST,REDIS_PORT)

end
