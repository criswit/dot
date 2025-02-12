#!/bin/bash
# ========== LIBRARY =========#

# If this is not sourced/imported, a `return` at top level of a script will error out
# We don't want users to call these scripts directly.
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ ${sourced} == 1 ]]; then
	: # printf "[WARN] This is a shell library, and should be sourced with 'source <library>' in order to use the functions within the package.\n" >&2
fi

# ========== GLOBAL VAR DEF =========#
export USE_LOG_FILE="" # Whether we have a LOG_FILE or not. Default to it not being set
export LOG_FILE=""     # Log file location. Overwrite any potentially existing collisions.

# ========== FUNCTIONS =========#

# Function: logger_setup
#
# This function serves as the main initialization for specifying configuration options
# for the logger. This logger adds additional formatting and log file specification
#
# Parameters:
# $1 (string) - log_file
#
# Prints: Information on the logger setup
#
# Returns:
# 0 - Success.
# 1 - Invalid log file chosen
logger_setup() {
	local log_file=$1
	local timestamp=$(date +'%Y-%m-%d %H:%M:%S')

	printf "%s [INFO] Setting up logger configuration. Log file location set to: %s\n" "${timestamp}" "${log_file}"

	log_dir=$(dirname "${log_file}")
	printf "%s [INFO] Log base directory: %s\n" "${timestamp}" "${log_dir}"

	if [[ ! -d "${log_dir}" ]]; then
		printf "[INFO] Log directory \"%s\" does not exist. Creating it...\n" ${log_dir}
		mkdir -p "${log_dir}"
		if [[ $? -ne 0 ]]; then
			printf "[ERROR] Failed to create log directory %s. Logging only to STDOUT/STDERR\n" "${log_dir}" >&2
			return 1
		else
			printf "[INFO] Log directory created successfully: %s\n" "${log_dir}"
			USE_LOG_FILE="True"
		fi
	fi

	touch "${log_file}" 2>/dev/null
	if [[ $? -ne 0 ]]; then
		log "ERROR" "Failed to create log file: ${log_file}. Logging only to STDOUT/STDERR"
		USE_LOG_FILE="False"
	else
		USE_LOG_FILE="True"
		LOG_FILE="${log_file}"
	fi

	log "DEBUG" "Logger configuration complete."
}

# Function: log
#
# This function serves as the main logger to be used in shell scripts.
# This logger adds additional formatting and prefixes to log statements to more
# closely resemble log4j (Java) or Go's logger
#
# Parameters:
# $1 (string) - logging level
# $2 (int) - Message passed in to be logged
#
# Prints: Fully formated log message including time, prefix and Log level
#
# Returns:
# 0 - Success.
# 1 - Invalid logging level
function log() {
	local log_level=""
	local message=""
	local timestamp=$(date +'%Y-%m-%d %H:%M:%S')

	if [[ $# -lt 2 ]]; then
		# Logging function only given one argument, so we will default to "INFO" logging level and that argument as the message
		log_level="INFO"
		message=$1
	else
		log_level=${1:-INFO}     # Set default to INFO if log level not passed in
		log_level=${log_level^^} # Standardize output by forcing uppercase
		message=$2
	fi

	case "${log_level}" in
	"TRACE")
		if [[ ${TRACE_DEBUGGING} == "True" ]]; then
			printf "%s [TRACE] %s\n" "${timestamp}" "${message}" >&2
		fi
		if [[ ${USE_LOG_FILE} == "True" ]]; then
			log_to_file "TRACE" "${message}" "${timestamp}"
		fi
		;;
	"DEBUG")
		if [[ ${DEBUG} == "True" ]]; then
			printf "%s [DEBUG] %s\n" "${timestamp}" "${message}" >&2
		fi
		if [[ ${USE_LOG_FILE} == "True" ]]; then
			log_to_file "DEBUG" "${message}" "${timestamp}"
		fi
		;;
	"INFO")
		printf "\e[34m%s\e[0m \e[32m[INFO]\e[0m \e[1m%s\e[0m\n" "${timestamp}" "${message}"
		if [[ ${USE_LOG_FILE} == "True" ]]; then
			log_to_file "INFO" "${message}" "${timestamp}"
		fi
		;;
	"WARN")
		printf "%s [WARN] %s\n" "${timestamp}" "${message}"
		if [[ ${USE_LOG_FILE} == "True" ]]; then
			log_to_file "WARN" "${message}" "${timestamp}"
		fi
		;;
	"ERROR")
		printf "\e[34m%s\e[0m \e[31m[ERROR]\e[0m \e[1m%s\e[0m\n" "${timestamp}" "${message}" >&2
		if [[ ${USE_LOG_FILE} == "True" ]]; then
			log_to_file "ERROR" "${message}" "${timestamp}"
		fi
		;;
	"FATAL")
		printf "%s [FATAL] %s\n" "${timestamp}" "${message}" >&2
		if [[ ${USE_LOG_FILE} == "True" ]]; then
			log_to_file "FATAL" "${message}" "${timestamp}"
		fi
		;;
	*)
		printf "%s [FATAL] \"%s\" is not a valid logging level.\nValid logging levels for the log() function are: TRACE, DEBUG, INFO, WARN, ERROR, FATAL\n" "${timestamp}" "${log_level}"
		if [[ ${USE_LOG_FILE} == "True" ]]; then
			log_to_file "FATAL" "${message}" "${timestamp}"
		fi
		;;
	esac
}

# Function: log_to_file
#
# Function to send log messages to a file.
#
# Parameters:
# $1 (string) log_level for log message to be sent to file
# $2 (string) message to be sent to file
# $3 (string) timestamp to be sent to file
#
# Prints: Fully formated debug log message including time, prefix and Log level to a log level
#
# Returns:
# 0 - Success.
# 1 - Unable to log to the file
log_to_file() {
	local log_level=$1
	local message=$2
	local timestamp=$3
	local log_file=${LOG_FILE}

	if [[ -n ${log_file} ]]; then
		printf "%s [${log_level}] %s\n" "${timestamp}" "${message}" >>${log_file}
	fi
}

# Function: log_trace
#
# A wrapper function for the logger to mimic pythons way of logging levels: log.warn()
#
# Parameters:
# $1 (string) Message passed in to be logged
#
# Prints: Fully formated debug log message including time, prefix and Log level
#
# Returns:
# 0 - Success.
# 1 - Invalid logging level
function log_trace() {
	local message=$1

	log "TRACE" "${message}"
}

# Function: log_debug
#
# A wrapper function for the logger to mimic pythons way of logging levels: log.warn()
#
# Parameters:
# $1 (string) Message passed in to be logged
#
# Prints: Fully formated debug log message including time, prefix and Log level
#
# Returns:
# 0 - Success.
# 1 - Invalid logging level
function log_debug() {
	local message=$1

	log "DEBUG" "${message}"
}

# Function: log_info
#
# A wrapper function for the logger to mimic pythons way of logging levels: log.warn()
#
# Parameters:
# $1 (string) Message passed in to be logged
#
# Prints: Fully formated INFO log message including time, prefix, INFO Log level and message
#
# Returns:
# 0 - Success.
# 1 - Invalid logging level
function log_info() {
	local message=$1

	log "INFO" "${message}"
}

# Function: log_warn
#
# A wrapper function for the logger to mimic pythons way of logging levels: log.warn()
#
# Parameters:
# $1 (string) Message passed in to be logged
#
# Prints: Fully formated WARN log message including time, prefix, WARN Log level and message
#
# Returns:
# 0 - Success.
# 1 - Invalid logging level
function log_warn() {
	local message=$1

	log "WARN" "${message}"
}

# Function: log_error
#
# A wrapper function for the logger to mimic pythons way of logging levels: log.warn()
#
# Parameters:
# $1 (string) Message passed in to be logged
#
# Prints: Fully formated ERROR log message including time, prefix, ERROR Log level and message
#
# Returns:
# 0 - Success.
# 1 - Invalid logging level
function log_error() {
	local message=$1

	log "ERROR" "${message}"
}

# Function: log_fatal
#
# A wrapper function for the logger to mimic pythons way of logging levels: log.warn()
#
# Parameters:
# $1 (string) Message passed in to be logged
#
# Prints: Fully formated FATAL log message including time, prefix, FATAL Log level and message
#
# Returns:
# 0 - Success.
# 1 - Invalid logging level
function log_fatal() {
	local message=$1

	log "FATAL" "${message}"
}