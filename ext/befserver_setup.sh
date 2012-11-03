#!/bin/bash

################################ About ################################
#
# Description:
#  This script helps you to setup a complete ruby on rails deployment server
#  (Ubuntu 12.04) for the BEFdata project. Using the following components:
#   
#   o Apache
#   o Postgresql
#   o Ruby/Rails
#   o Passenger
#
#  It can also install several security features to harden the server system 
#  and enable you to track suspicious activity on your server. The following
#  softare and feautures will be installed.
#
#   o sysctl.conf modifications
#   o fail2ban (block suspicious ips)
#   o ufw firewall  (allow http and ssh, forbid everything else)
#   o apache mod-security (web application firewall)/mod-evasive (against ddos attacks)
#   o tiger (security audit tool)
#   o nmap (port scanner)
#   o psad (port scan detection)
#   o rkhunter/chkrootkit (rootkit detection)
#   o logwatch (nice logs)
# 
#  The script can also setup database and application backups. It runs the backup 
#  The backups are run weekly for a full application folder and database backup. And
# 	daly for the application database. These backups are stored in the folder:
#
#   o /root/backup/application_name/
# 
# Notes:
#  You can alter the behaviour of the application in the sections below. Next to
#  the unattended setup you can enable or disable the security setup and 
#  application backups. Furthermore you can fine tune the behaviour of the script
#  in the advanced setup section. 
#
# Disclaimer:
# 	This software comes without any warranty. Use at your own risk!
#
# Meta:
#
#  Author: Claas-Thido Pfaff 
#  Copyright: Claas-Thido Pfaff
#
#######################################################################


############################## Unattended #############################
#
# Description:
#  This section can be used to configure an unattended script run. You need to
#  swich the unattended_install variable from "off" to "on" and make sure to
#  provide all informations the script needs to set up the server by filling all
#  the variables below with values.

# Unattended on/off
unattended_install=on

# Set informations

server_url=
# e.g server_url=http://mywebsite.com
# This is the address your sever is reachable over the browser

postgres_user_admin_pwd=
# e.g postgres_user_admin_pwd=pgadminpwd
# The postgers database admin password. You can set it to whatever you like.
# you can change this password again later in the psql console 
# sudo -u postgres psql

postgres_user_app_db=
# e.g postgres_user_app_db=pgbefdeploy
# This is the owner of the postgres database for your application.

postgres_user_app_db_pwd=
# e.g postgres_user_app_db_pwd=pgbefdeploypwd
# This is the password of the owner of the postgres database for your application.

postgres_database_app_db=
# e.g postgres_database_app_db=pgbefdeploydb
# This is the database name of your application

install_app_ruby_environment=
# Usually you can leave this as it is. If you need to setup a second environment
# of the same application parallel you can run the script twice. For the second
# run you need to change the environment variable (e.g to staging, testing
# or whatever you like), the URL, the database name, the user name and the
# passwords.

do_security_setup=on
# You can enable or disable (off) the system security setup for your server. It
# is recommended to leave it on because it hardens your system against hacker
# attacks. Note that this setup is only a good start to secure your system and
# does not prevent you to deal with security issues.
# Note:
#  If you have security on then it will install a mailserver (postfix) as
#  dependency to psad which is responsible for intrusion detection. Postfix
#  will ask you two question for configuration even if you have chosen 
#  uattended. If you do not know what to chose you should use:
#  
#   o chose local only (hit enter)
#   o leave the second option as is (hit enter)

do_backup_setup=on
# This option enables or disables (off) the backup of your application setup.
# The backups are defined as a weekly dump of the full database and a dump
# of your application database every night. The path the files are stored is
# /root/backups/ you can change the backup user and the path the backup goes to
# under the advanced setup section below.

#######################################################################


######################### Advanced setup #########################
#
# Warning:
#  Please change the variables below only if you know what you do!
#
# Description:
#  This section can be used to alter paths, files, programs, users, and
#  installed packages the script uses for the server setup.

# System information
server_os_version="ubuntu 12.04"

# Users
postgres_user_admin=postgres
apache_user_admin=www-data
database_backup_user=root
app_folder_backup_user=root

# Program calls
program_call_ruby=ruby

# Install environment
install_app_name=befdata #same as the name on github (Case sensitive)
install_app_git_url=https://github.com/befdata/befdata.git
install_app_std_username=admin
install_app_std_pwd=test

# Define paths
path_www=/var/www
path_www_environment=${path_www}/${install_app_ruby_environment}
path_www_environment_application=${path_www_environment}/${install_app_name}
path_www_environment_application_public=${path_www_environment_application}/public
path_www_environment_application_config=${path_www_environment_application}/config

path_app_backup=/root/backup/${install_app_name}

# Cronjob timings
database_app_backup_frequency=@midnight
database_full_backup_frequency=@weekly
app_folder_backup_frequency=@weekly

# Define files
file_app_database_conf=${path_www_environment_application_config}/database.yml

file_apache2_apache2_conf=/etc/apache2/apache2.conf
file_apache2_httpd_conf=/etc/apache2/httpd.conf
file_apache2_mods_available_modsecurity_conf=/etc/apache2/mods-available/mod-security.conf
file_apache2_mods_available_modevasive_conf=/etc/apache2/mods-available/mod-evasive.conf

file_ssh_server_conf=/etc/ssh/sshd_config
file_sysctl_sysctl_conf=/etc/sysctl.conf
file_fstab_fstab=/etc/fstab
file_host_host_conf=/etc/host.conf
file_cron_crontab=/etc/crontab

file_modsecurity_modsecurity_conf=/etc/modsecurity/modsecurity.conf
file_modsecurity_ignore_conf=/etc/modsecurity/base_rules/modsecurity_crs_60_myignores.conf

file_this_script_logfile=/tmp/install_${install_app_ruby_environment}_${install_app_name}.log

# Define ppa sources and packages 
sources_ppa=(ppa:brightbox/ruby-ng)

# Ubuntu standard packages
packages_native_basic=(git-core apache2 postgresql openssh-server libyaml-dev libxml2-dev zlib1g-dev libaprutil1-dev build-essential openssl libapr1-dev libssl-dev libreadline6-dev python-software-properties apache2-prefork-dev imagemagick vim-nox libdate-manip-perl)

# Ubuntu standard security packages
packages_native_security=(libapache-mod-security libapache2-mod-evasive fail2ban ufw psad chkrootkit rkhunter apparmor apparmor-profiles tiger nmap logwatch) 

# Additional packages from ppa: the package 1.9.1 installs 1.9.3
packages_ppa=(ruby1.9.1 ruby1.9.1-dev rubygems libcurl4-openssl-dev)

# Installation of gems 
packages_gem=(rails passenger bundler)

#######################################################################


################## Application specific configuration hook #################
#
# Description:
#  This function is called right after cloning into the application via git. You
#  can put your own application specific configuration steps in here. You can do
#  it with an if statement like the one below for befdata. So you make sure the
#  steps get only executed when setting up that special application.

function app_specific_configuration_steps()
{

if [ ${install_app_name} == "befdata" ]
	then
		file_name_init_befdata_delayed_job=befdata_delayed_job
		file_init_befdata_delayed_job=/etc/init.d/befdata_delayed_job

		pushd ${path_www_environment_application_config}
			sudo_execute_command "Rename database.yml distribution file" "cp database.yml.dist database.yml"
			sudo_execute_command "Rename configuration.yml distribution file" "cp configuration.yml.dist configuration.yml"
		popd

# Define startup script for BEFdata
here_befdata_background_worker_startup_script=$(cat <<EOF
#! /bin/sh

case "\${1}" in
	start|s)
		echo "starting befdata_delayed_job_backgroundworker from ${path_www_environment_application}" 
		sudo -u ${apache_user_admin} ${program_call_ruby} ${path_www_environment_application}/script/delayed_job_${install_app_ruby_environment} start
		;;  
	restart|r)
		\${0} stop
		\${0} start
		;;  
	stop|k)
		echo "stopping befdata_delayed_job_backgroundworker from ${path_www_environment_application}"
		sudo -u ${apache_user_admin} ${program_call_ruby} ${path_www_environment_application}/script/delayed_job_${install_app_ruby_environment} stop
		exit
		;;  
	*)  
		echo "usage: \${0} {start|stop|restart}"
		exit 3

		;;  
esac
EOF
)

		sudo_write_file "${here_befdata_background_worker_startup_script}" "${file_init_befdata_delayed_job}"
		sudo_execute_command "Set rights for background worker startup script" "chmod a+x ${file_init_befdata_delayed_job}"
		sudo_execute_command "Enable background worker startup script" "update-rc.d befdata_delayed_job defaults"
fi

}

#######################################################################


############################# Script Style ############################

frame_welcome="OO====================================================================================O0"
frame_metastep="O===================================================================O"
step_big="----------------------------------------------------------o"
step_small="---------------------------"

#######################################################################


############################ Define Messages ##########################

# Welcome message 

welcome_text_interactive_mode=$(cat <<EOF

This script will help you to setup a server for ${install_app_name} deployment.
It is designed to run on a fresh intall of the ${server_os_version} server
edition. You can run the installation process in unattended or interactive
mode. For both modi you need to provide some information to the script. The
interactive mode is standard an will ask you while the script is running for
required informations.

Required Information:

o server url 
o The script assigns passwords for:
	- database admin (postgres)
	- ${install_app_name} database name (postgres)
	- ${install_app_name} database user and password (postgres)

If you prefer an unattended installation mode you should answer the question
below with no, to cancel this interactive mode process. After that you need to
edit the unattended section in the beginning of this script with any texteditor
you like and then start it again. You will fine additional informations and
examples there. The unattended mod has the advantage that you can check
your data twice to be right and do not have to modify later on the system
configuration files to change wrong or misspelled informations.

EOF
)

welcome_text_unattended_mode=$(cat <<EOF

You have chosen to run the script in unattended mode. The informations you
provided to the script are displayed below. Check them a last time and then
start the script run.

Note:
 If you have the security option set to "on" the script will install postfix
 as dependency to psad, which is used for intrusion detection. The postfix
 mailserver will ask you two questions for configuration. If you do not know
 what options are the right for you you should use:

  o chose local only (hit enter)
  o leave the second option as is (hit enter)

EOF
)


# Help messages

url_help_message=$(cat <<EOF

You need to provide your server URL to the script. You can get this URL from
the admins who provide you with the server infrastructure (e.g Univertiy
IT guys). The script will use the URL to setup the apache virtual host
configuration. After that the server responds to the URL and delivers your
application. You can find the configuration in the apache configuration file
under "/var/apache2/apache2.conf".

Example URL:

http://befdeploy.dyndns-free.org

EOF
)

postgres_help_message=$(cat <<EOF

You need to setup the admin password for the postgres database, a new database
for your ${install_app_name} ${install_app_ruby_environment} system and a user
for that database with a password. The command "sudo -u postgres psql" opens
the postgresql console. You can use this console to maintain your users and
databases later on. 

EOF
)

befdata_help_message=$(cat <<EOF

The following steps prepare your ${install_app_name} instance in the folder
${path_www_environment_application}. Your can find the configuration files of
the application in the ${path_www_environment_application_config}.

EOF
)

#######################################################################


############################ Define Functions #########################

function welcome_user()
{
	if [ ${unattended_install} == "on" ]
	then

		welcome_frame_display "Welcome to the ${install_app_name} server setup script" "${welcome_text_unattended_mode}"

		echo "o Server URL: " ${server_url} 
		echo "" 
		echo "o Posgres database admin pwd: " ${postgres_user_admin_pwd} 
		echo "" 
		echo "o Postgres application database user: " ${postgres_user_app_db} 
		echo "" 
		echo "o Postgres application database user password: " ${postgres_user_app_db_pwd} 
		echo "" 
		echo "o Postgres application database name: " ${postgres_database_app_db} 
		echo "" 
		echo "o System security: " ${do_security_setup} 
		echo "" 
		echo "o Application backup: " ${do_backup_setup} 
		echo ${step_small}

		ask_to_proceed "Are the informations above correct"
	else
		welcome_frame_display "Welcome to the ${install_app_name} server setup script" "${welcome_text_interactive_mode}"

		ask_to_proceed "Do you want to proceed in interactive mode"
	fi

}

function ask_to_proceed()
{
	while true 
	do
		read -p "${1} [y/N]?: " answer 
		case "$answer" in
			Yes|yes|Y|y) 
				break
				;;
			No|no|N|n|"") 
				exit 0
				;;
			*) echo "Unknown parameter. Try again!" 
				;;
		esac
	done
}

function welcome_frame_display()
{
	clear
	echo ${frame_welcome}
	echo -e "\t\t" "${1}"
	echo ${frame_welcome}
	echo ""
	echo "${2}"
	echo ""
	echo ${frame_welcome} 
	echo ""
}

function meta_step_display()
{
	clear
	echo ${frame_metastep}
	echo -e "\t" "${1}"
	echo ${frame_metastep}
	echo ""
}

function big_step_display()
{
	echo ""
	echo ${step_big}
	echo "${1}"
	echo ${step_big}
	echo ""
}

function small_step_display()
{
	echo ""
	echo ${step_small}
	echo "${1}"
	echo ${step_small}
	echo ""
}

function display_step_help()
{
	echo ""
	echo "${1}" 
	echo ""
}

function write_log_entry()
{
	echo "${1}" >> ${file_this_script_logfile}	
}

function check_for_process_error()
{
	if [ ${?} -eq "0" ]
	then
		write_log_entry "The function ${FUNCNAME[1]}: ${2} OK"  
	else
		write_log_entry "The function ${FUNCNAME[1]}: ${1} ${2}"  
	fi	
}

function throw_error_message()
{
	echo ""
	echo ${step_small}
	echo ""
	echo "${1}" 
	echo ""
	echo "${2}" 
	echo ""
	echo ""
	write_log_entry "The function ${FUNCNAME[1]}: ${1} ${2} exit status ${3}"
	exit ${3} 
}

function check_who_is_user()
{
	if [[ $EUID -ne 0 ]]
	then
		throw_error_message "This script must be run as root user!" "Use: sudo ${0}" 1
	fi
}

function check_unattended_setup()
{
	if [ ${unattended_install} == "on" ]
	then
		if [ -z ${server_url} ] || 
			[ -z ${postgres_user_admin_pwd} ] ||
			[ -z ${postgres_user_app_db} ] ||
			[ -z ${postgres_user_app_db_pwd} ] ||
			[ -z ${postgres_database_app_db} ] 
		then 
			throw_error_message "You chose an unattended setup but one or more of the required variables are unset!" "Check all variables in the unattended section of the script." 1
		else
			:
		fi
	else
		:
	fi
}

function ask_for_input()
{
	if [ ${unattended_install} == "on" ]
	then
		:
	else
		echo ""
		read -p "${1}: " ${2} 
		echo ""
	fi
}

function sudo_add_repository ()
{
	big_step_display "Add repositories"

	for repo in "$@"
	do
		echo "Adds:" ${repo}
		sudo apt-add-repository -y ${repo}
		check_for_process_error "Problems adding the repository:" ${repo}
		echo ${step_small}
	done

	sudo apt-get update 
}

function sudo_install_packages() 
{
	big_step_display "Install packages"

	for package in "$@"  
	do
		if dpkg -s ${package} &> /dev/null
		then 
			echo "${package} already installed: skip"
		else 
			echo "Installs" ${package}
			sudo apt-get -y install ${package} 
			check_for_process_error "Problems installing the package:" ${package}
			echo ${step_small}
		fi

	done
}

function sudo_install_gems()
{
	big_step_display "Install required gems"

	for gem in "$@"  
	do
		if gem list ${gem} -i
		then
			echo "${gem} already installed: skip"
		else 
			echo "Installs" ${gem}
			sudo gem install ${gem}
			check_for_process_error "Problems installing the gem:" ${gem}
			echo ${step_small}
		fi
	done
}

function sudo_execute_command()
{
	big_step_display "${1}"

	sudo ${2}
	check_for_process_error "Problems executing the command" ${2}
}

function sudo_execute_psql_command()
{
	big_step_display "${1}"

# do not indent it does not work 
sudo -u postgres psql <<EOF
${2} 
EOF
}

function sudo_backup_file()
{
	big_step_display "Backup up a file"

	echo "Backup" ${1}
	if [ -e ${1}.orig ]
	then
		sudo cp ${1}{,.bck}
		check_for_process_error "Problems backing up the file" ${1}
	else
		sudo cp ${1}{,.bck}
		check_for_process_error "Problems backing up the file" ${1}
		sudo cp ${1}{,.orig}
		check_for_process_error "Problems backing up the file" ${1}
	fi
}

function sudo_restore_original()
{
	big_step_display "Restore original file"

	echo "Restore" ${1}

	if [ -e ${1}.orig ]
	then
		sudo cp ${1}.orig ${1}
		check_for_process_error "Problems restoring original file" ${1}
	else
		:
	fi
}

function sudo_write_file()
{
	big_step_display "Write a file"

	echo "Write content:" 
	echo ${step_small}
	echo ""
	echo "${1}"
	echo ""
	echo "To destination:" 
	echo ${step_small}
	echo ""
	echo ${2}
	echo ""
	echo "${1}" | sudo tee ${2} &> /dev/null	
	check_for_process_error "Problem in writing the file" ${1}
}

function sudo_append_to_file()
{
	big_step_display "Append to a file"

	echo "Appends what:" 
	echo ${step_small}
	echo ""
	echo "${1}"
	echo ""
	echo "To destination:" 
	echo ${step_small}
	echo ""
	echo "${4}"
	echo ""
	if grep "${2}" ${4} &> /dev/null 
	then
		: 
	else
		echo "${3}" | sudo tee -a ${4} &> /dev/null
		check_for_process_error "Problem in appending to the file" ${4}
	fi
}


## Define meta functions

install_basics_gems_and_repos()
{
	meta_step_display "Installing sources, packages and gems:"

	sudo_install_packages "${packages_native_basic[@]}"

	sudo_add_repository "${sources_ppa[@]}"

	sudo_install_packages "${packages_ppa[@]}"

	sudo_install_gems "${packages_gem[@]}"

	# Start mod_rails installer if not already installed 
	if [ -e /var/lib/gems/1.9.1/gems/passenger-3.0.17/ext/apache2/mod_passenger.so ]
	then
		echo "Passenger is installed already: skip compilation"
	else
		sudo_execute_command "Install passenger rails deployment" "passenger-install-apache2-module -a"
	fi
}


function configure_apache_server()
{

## Define all configuration files

# apache general configuration
apache_server_general_configuration=$(cat <<EOF
## app ${install_app_name} general options 

# set server name
ServerName localhost 

# Hide the Apache Version number, and other sensitive information
ServerSignature Off
ServerTokens Prod

# Lower the Timeout value
Timeout 45

# Turn off directory browsing
Options -Indexes

# Turn off server side includes
Options -Includes

# Turn off CGI execution
Options -ExecCGI

# Don not allow apache to follow symbolic links
Options -FollowSymLinks

LoadModule passenger_module /var/lib/gems/1.9.1/gems/passenger-3.0.17/ext/apache2/mod_passenger.so
PassengerRoot /var/lib/gems/1.9.1/gems/passenger-3.0.17
PassengerRuby /usr/bin/ruby1.9.1

# Ensure that files outside the web root are not served
<Directory />
  Order Deny,Allow
  Deny from all
  Options None
  AllowOverride None
</Directory>

EOF
)

# apache app and environment specific configuration
apache_server_environment_configuration=$(cat <<EOF
## app ${install_app_name} ${install_app_ruby_environment} options 


# Do not allow to look into 
<Directory ${path_www}>
  Order Deny,Allow
  Deny from all
  Options None
  AllowOverride None
</Directory>

<Directory ${path_www_environment}>
  Order Deny,Allow
  Deny from all
  Options None
  AllowOverride None
</Directory>

<Directory ${path_www_environment_application}>
  Order Deny,Allow
  Deny from all
  Options None
  AllowOverride None
</Directory>

# Allow to look into
<Directory ${path_www_environment_application_public}>
  Order Allow,Deny
  Allow from all
</Directory>

# Setup the virtual host
<VirtualHost *:80>
	# Define server URL (this is the url the virtual host responds to) 
	ServerName ${server_url}

	# The root of the application
	DocumentRoot ${path_www_environment_application_public}

	# Rules for the root of the application
	<Directory ${path_www_environment_application_public}>
		# This relaxes Apache security settings.
		AllowOverride all

		# MultiViews must be turned off.
		Options -MultiViews

	</Directory>
</VirtualHost>
EOF
)

# Prepare redirects
apache_server_redirect=$(cat <<EOF

RewriteEngine On
ErrorDocument 403 ${server_url}/404
ErrorDocument 404 ${server_url}/404
RewriteEngine Off

EOF
)

## Now do the work 

	meta_step_display "Configure Apache server:"

	display_step_help "${url_help_message}"

	ask_for_input "Please enter server URL" server_url

	sudo_backup_file ${file_apache2_apache2_conf} 
	sudo_append_to_file "Write general Apache configuration" "app ${install_app_name} general options" "${apache_server_general_configuration}" ${file_apache2_apache2_conf}  
	sudo_append_to_file "Write ${install_app_name} ${install_app_ruby_environment} apache configuration" "app ${install_app_name} ${install_app_ruby_environment} options"  "${apache_server_environment_configuration}" ${file_apache2_apache2_conf}  

	sudo_execute_command "Enable redirects" "a2enmod rewrite"
	sudo_backup_file ${file_apache2_httpd_conf} 
	sudo_append_to_file "Apache redirect configuration" "RewriteEngine On" "${apache_server_redirect}" ${file_apache2_httpd_conf}  

	sudo_execute_command "Restarting the Apache server" "service apache2 restart"
}

function configure_postgresql_database()
{
	meta_step_display "Configure postgresql database"

	display_step_help "${postgres_help_message}"

	big_step_display "Change postgresql admin password"
	ask_for_input "Enter password for postgres admin" postgres_user_admin_pwd
	sudo_execute_psql_command "Set database admin password" "ALTER ROLE ${postgres_user_admin} with PASSWORD '${postgres_user_admin_pwd}'"

	big_step_display "Create ${install_app_ruby_environment} database user"
	ask_for_input "Enter username" postgres_user_app_db
	ask_for_input "Enter password" postgres_user_app_db_pwd
	sudo_execute_psql_command "Create user ${postgres_user_app_db}" "CREATE ROLE ${postgres_user_app_db} PASSWORD '${postgres_user_app_db_pwd}' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;" 

	big_step_display "Input ${install_app_ruby_environment} database name"
	ask_for_input "Enter database name" postgres_database_app_db
	sudo_execute_psql_command "Create database ${postgres_database_app_db}" "CREATE DATABASE ${postgres_database_app_db} OWNER ${postgres_user_app_db};" 

	sudo_execute_command "Restarting postgres database" "service postgresql restart"
}

function configure_app_instance()
{

## Define all configuration files

# prepare app database.yml (do not indent) 
here_app_database_yml=$(cat <<EOF
production:
  adapter: postgresql
  host: localhost
  port: 5432
  encoding: unicode
  database: ${postgres_database_app_db}
  pool: 5
  username: ${postgres_user_app_db}
  password: ${postgres_user_app_db_pwd}
EOF
)

## Now do the work 

	meta_step_display "Configuring your ${install_app_name} instance:"

	# Display help text for postresql 
	display_step_help "${befdata_help_message}"

	sudo_execute_command "Create ${install_app_ruby_environment} folder" "mkdir -p ${path_www_environment}"

	pushd ${path_www_environment}
		sudo_execute_command "Cloning into ${install_app_name}" "git clone ${install_app_git_url}"
	popd

	pushd ${path_www_environment_application_config} 
		# Calls the function for app specifig configuration steps
		app_specific_configuration_steps
	popd

	sudo_backup_file ${file_app_database_conf}

	sudo_write_file "${here_app_database_yml}" "${file_app_database_conf}"

	pushd ${path_www_environment_application}
		sudo_execute_command "Intall ${install_app_name} bundle" "bundle install"
		sudo_execute_command "Rake setup ${install_app_name} database" "rake db:setup RAILS_ENV=production"
	popd

	sudo_execute_command "Set right permissions: ${path_www_environment_application_public}" "chmod -R 777 ${path_www_environment_application_public}" 

	sudo_execute_command "Set owner of: ${path_www_environment_application}" "chown -R www-data:www-data ${path_www_environment_application}/*"
}

function setup_backup_strategy()
{

	#configure it to more than one variable
	if [ ${install_app_ruby_environment} == "production" ]
		then
			meta_step_display "Set up the backup strategy for ${install_app_name}"
			
			sudo_execute_command "Create backup folder" "mkdir -p ${path_app_backup}"


database_app_backup_frequency=@midnight
database_full_backup_frequency=@weekly

#please do not indent its not working
here_database_backup_conjob=$(cat <<EOF
# app ${install_app_name}

# Selective ${install_app_name} database backup 
${database_app_backup_frequency} ${database_backup_user} sudo su ${postgres_user_admin} pg_dump -Fc ${postgres_database_app_db} | sudo tee ${path_app_backup}/\$(date +"\%Y\%m\%d-\%H\%M")_${install_app_name}_${postgres_database_app_db}.dump

# Full database backup 
${database_full_backup_frequency} ${database_backup_user} sudo su ${postgres_user_admin} pg_dumpall | sudo tee ${path_app_backup}/\$(date +"\%Y\%m\%d-\%H\%M")_${install_app_name}_alldb.dump

# Full database backup 
${app_folder_backup_frequency} ${app_folder_backup_user} cd ${path_app_backup}; tar -czf \$(date +"\%Y\%m\%d-\%H\%M")_${install_app_name}_app_folder.tgz ${path_www_environment_application} 

EOF
)

			sudo_backup_file ${file_cron_crontab}

			sudo_append_to_file "Crontab backup configuration" "app ${install_app_name}" "${here_database_backup_conjob}" ${file_cron_crontab} 
		else
			:
	fi
}


# Setup for system security

function harden_the_system()
{

## Define all configuration files

# sysctl configuration
here_sysctl_config=$(cat <<EOF
# app ${install_app_name}

# Avoid a smurf attack
net.ipv4.icmp_echo_ignore_broadcasts = 1
 
# Turn on protection for bad icmp error messages
net.ipv4.icmp_ignore_bogus_error_responses = 1
 
# Turn on syncookies for SYN flood attack protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Turn on and log spoofed, source routed, and redirect packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
 
# No source routed packets here
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Turn on reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
 
# Make sure no one can alter the routing tables
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv6.conf.default.secure_redirects = 0
 
# Do not act as a router
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
 
# Turn on execshild
kernel.exec-shield = 1
kernel.randomize_va_space = 1
 
# Tune IPv6
net.ipv6.conf.default.router_solicitations = 0
net.ipv6.conf.default.accept_ra_rtr_pref = 0
net.ipv6.conf.default.accept_ra_pinfo = 0
net.ipv6.conf.default.accept_ra_defrtr = 0
net.ipv6.conf.default.autoconf = 0
net.ipv6.conf.default.dad_transmits = 0
net.ipv6.conf.default.max_addresses = 1
 
# Increase system file descriptor limit
fs.file-max = 65535
  
# Increase system IP port limits
net.ipv4.ip_local_port_range = 2000 65000
 
# Increase TCP max buffer size setable 
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 87380 8388608
 
# Increase Linux auto tuning TCP buffer limits
net.core.rmem_max = 8388608
net.core.wmem_max = 8388608
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_window_scaling = 1

# Allow 128 MB shared memory (use in postgresql)
kernel.shmmax=1073741824

EOF
)

# ssh server configuration 
here_ssh_server_config=$(cat <<EOF
# app ${install_app_name}
PermitRootLogin no
EOF
)

# fstab appendix for secured shared memory
here_fstab_secure_shmem=$(cat <<EOF
# app ${install_app_name}
tmpfs     /dev/shm     tmpfs     defaults,noexec,nosuid     0     0
EOF
)

# /etc/host.conf
here_etc_host_conf=$(cat <<EOF
# app ${install_app_name}
nospoof on
EOF
)

# modified modsecurity configuration
here_modsecurity_conf=$(cat <<EOF
# app ${install_app_name}

# -- Rule engine initialization ----------------------------------------------

# Enable ModSecurity, attaching it to every transaction. Use detection
# only to start with, because that minimises the chances of post-installation
# disruption.
#
SecRuleEngine On

#DetectionOnly

# -- Request body handling ---------------------------------------------------

# Allow ModSecurity to access request bodies. If you don't, ModSecurity
# won't be able to see any POST parameters, which opens a large security
# hole for attackers to exploit.
#
SecRequestBodyAccess On

# Enable XML request body parser.
# Initiate XML Processor in case of xml content-type
#
SecRule REQUEST_HEADERS:Content-Type "text/xml" \
     "phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=XML"

# Maximum request body size we will accept for buffering. If you support
# file uploads then the value given on the first line has to be as large
# as the largest file you are willing to accept. The second value refers
# to the size of data, with files excluded. You want to keep that value as
# low as practical.
#
SecRequestBodyLimit 13107200
SecRequestBodyNoFilesLimit 131072

# Store up to 128 KB of request body data in memory. When the multipart
# parser reachers this limit, it will start using your hard disk for
# storage. That is slow, but unavoidable.
#
SecRequestBodyInMemoryLimit 131072

# What do do if the request body size is above our configured limit.
# Keep in mind that this setting will automatically be set to ProcessPartial
# when SecRuleEngine is set to DetectionOnly mode in order to minimize
# disruptions when initially deploying ModSecurity.
#
SecRequestBodyLimitAction Reject

# Verify that we ve correctly processed the request body.
# As a rule of thumb, when failing to process a request body
# you should reject the request (when deployed in blocking mode)
# or log a high-severity alert (when deployed in detection-only mode).
#
SecRule REQBODY_ERROR "!@eq 0" \
"phase:2,t:none,log,deny,status:400,msg:'Failed to parse request body.',logdata:'%{reqbody_error_msg}',severity:2"

# By default be strict with what we accept in the multipart/form-data
# request body. If the rule below proves to be too strict for your
# environment consider changing it to detection-only. You are encouraged
# _not_ to remove it altogether.
#
SecRule MULTIPART_STRICT_ERROR "!@eq 0" \
"phase:2,t:none,log,deny,status:44,msg:'Multipart request body \
failed strict validation: \
PE %{REQBODY_PROCESSOR_ERROR}, \
BQ %{MULTIPART_BOUNDARY_QUOTED}, \
BW %{MULTIPART_BOUNDARY_WHITESPACE}, \
DB %{MULTIPART_DATA_BEFORE}, \
DA %{MULTIPART_DATA_AFTER}, \
HF %{MULTIPART_HEADER_FOLDING}, \
LF %{MULTIPART_LF_LINE}, \
SM %{MULTIPART_SEMICOLON_MISSING}, \
IQ %{MULTIPART_INVALID_QUOTING}, \
IH %{MULTIPART_INVALID_HEADER_FOLDING}, \
IH %{MULTIPART_FILE_LIMIT_EXCEEDED}'"

# Did we see anything that might be a boundary?
#
SecRule MULTIPART_UNMATCHED_BOUNDARY "!@eq 0" \
"phase:2,t:none,log,deny,status:44,msg:'Multipart parser detected a possible unmatched boundary.'"

# PCRE Tuning
# We want to avoid a potential RegEx DoS condition
#
SecPcreMatchLimit 100000
SecPcreMatchLimitRecursion 100000

# Some internal errors will set flags in TX and we will need to look for these.
# All of these are prefixed with "MSC_".  The following flags currently exist:
#
# MSC_PCRE_LIMITS_EXCEEDED: PCRE match limits were exceeded.
#
SecRule TX:/^MSC_/ "!@streq 0" \
        "phase:2,t:none,deny,msg:'ModSecurity internal error flagged: %{MATCHED_VAR_NAME}'"


# -- Response body handling --------------------------------------------------

# Allow ModSecurity to access response bodies. 
# You should have this directive enabled in order to identify errors
# and data leakage issues.
# 
# Do keep in mind that enabling this directive does increases both
# memory consumption and response latency.
#
SecResponseBodyAccess On

# Which response MIME types do you want to inspect? You should adjust the
# configuration below to catch documents but avoid static files
# (e.g., images and archives).
#
SecResponseBodyMimeType text/plain text/html text/xml

# Buffer response bodies of up to 512 KB in length.
SecResponseBodyLimit 524288

# What happens when we encounter a response body larger than the configured
# limit? By default, we process what we have and let the rest through.
# That's somewhat less secure, but does not break any legitimate pages.
#
SecResponseBodyLimitAction ProcessPartial

# -- Filesystem configuration ------------------------------------------------

# The location where ModSecurity stores temporary files (for example, when
# it needs to handle a file upload that is larger than the configured limit).
# 
# This default setting is chosen due to all systems have /tmp available however, 
# this is less than ideal. It is recommended that you specify a location that's private.
#
SecTmpDir /tmp/

# The location where ModSecurity will keep its persistent data.  This default setting 
# is chosen due to all systems have /tmp available however, it
# too should be updated to a place that other users can't access.
#
SecDataDir /tmp/

# -- File uploads handling configuration -------------------------------------

# The location where ModSecurity stores intercepted uploaded files. This
# location must be private to ModSecurity. You don't want other users on
# the server to access the files, do you?
#
#SecUploadDir /opt/modsecurity/var/upload/

# By default, only keep the files that were determined to be unusual
# in some way (by an external inspection script). For this to work you
# will also need at least one file inspection rule.
#
#SecUploadKeepFiles RelevantOnly

# Uploaded files are by default created with permissions that do not allow
# any other user to access them. You may need to relax that if you want to
# interface ModSecurity to an external program (e.g., an anti-virus).
#
#SecUploadFileMode 0600

# -- Debug log configuration -------------------------------------------------

# The default debug log configuration is to duplicate the error, warning
# and notice messages from the error log.
#
#SecDebugLog /opt/modsecurity/var/log/debug.log
#SecDebugLogLevel 3

# -- Audit log configuration -------------------------------------------------

# Log the transactions that are marked by a rule, as well as those that
# trigger a server error (determined by a 5xx or 4xx, excluding 404,  
# level response status codes).
#
SecAuditEngine RelevantOnly
SecAuditLogRelevantStatus "^(?:5|4(?!04))"

# Log everything we know about a transaction.
SecAuditLogParts ABIJDEFHZ

# Use a single file for logging. This is much easier to look at, but
# assumes that you will use the audit log only ocassionally.
#
SecAuditLogType Serial
SecAuditLog /var/log/apache2/modsec_audit.log

# Specify the path for concurrent audit logging.
#SecAuditLogStorageDir /opt/modsecurity/var/audit/

# -- Miscellaneous -----------------------------------------------------------

# Use the most commonly used application/x-www-form-urlencoded parameter
# separator. There's probably only one application somewhere that uses
# something else so don't expect to change this value.
#
SecArgumentSeparator &

# Settle on version 0 (zero) cookies, as that is what most applications
# use. Using an incorrect cookie version may open your installation to
# evasion attacks (against the rules that examine named cookies).
#
SecCookieFormat 0

EOF
)

# Define modsecurity ignore rules
# Note:
# 	This are ignored rules of the web application firewall mod-security.
#  This is not a final solution! The definitions of the below listed rules
#  need some modifications to work together with your application. 

here_modsecurity_ignores=$(cat <<EOF
# app ${install_app_name}

SecRuleRemoveById 981318 
SecRuleRemoveById 970901
SecRuleRemoveById 981205
SecRuleRemoveById 950001
SecRuleRemoveById 959073
SecRuleRemoveById 981173 
SecRuleRemoveById 960024
SecRuleRemoveById 981257
SecRuleRemoveById 981243 
SecRuleRemoveById 973335 
SecRuleRemoveById 981247 
SecRuleRemoveById 981001

EOF
)

# Define mod-security inclusion for apache
here_apache_mods_available_modsecurity=$(cat <<EOF
# app ${install_app_name}

<IfModule security2_module>
        # Default Debian dir for modsecuritys persistent data
        SecDataDir /var/cache/modsecurity
        Include "/etc/modsecurity/*.conf"
        Include "/etc/modsecurity/activated_rules/*.conf"
</IfModule>

EOF
)

# Define the mod evasive configuration
here_apache_mods_available_evasive=$(cat << EOF
<ifmodule mod_evasive20.c>
   DOSHashTableSize 3097
   DOSPageCount  2
   DOSSiteCount  50
   DOSPageInterval 1
   DOSSiteInterval  1
   DOSBlockingPeriod  10
   DOSLogDir   /var/log/mod_evasive
   DOSEmailNotify  root@localhost
   DOSWhitelist   127.0.0.1
</ifmodule>
EOF
)

	## Now do the work 
	
	meta_step_display "Harden the system"
	
	sudo_install_packages "${packages_native_security[@]}"

	big_step_display "Write the sysctl configuration"

	sudo_backup_file ${file_sysctl_sysctl_conf}
	sudo_write_file "${here_sysctl_config}" "${file_sysctl_sysctl_conf}"
	sudo_execute_command "Enable sysctl values" "sysctl -p"


	big_step_display "Write ssh server configuration"

	sudo_backup_file ${file_ssh_server_conf}
	sudo_append_to_file "SSH server configuration" "app ${install_app_name}" "${here_ssh_server_config}" ${file_ssh_server_conf} 


	big_step_display "Set ufw firewall rules"

	sudo_execute_command "Firewall: Allow http connections" "ufw allow http"
	sudo_execute_command "Firewall: Allow ssh connections" "ufw allow ssh"
	# if ssh port is changed:
	#   sudo ufw allow 2233/tcp
	#   sudo ufw deny ssh 

	
	big_step_display "Secure the shared memory"

	sudo_backup_file ${file_fstab_fstab}
	sudo_append_to_file "Fstab configuration" "app ${install_app_name}" "${here_fstab_secure_shmem}" ${file_fstab_fstab} 


	big_step_display "Set configuration for host.conf"
	
	sudo_backup_file ${file_host_host_conf}
	sudo_append_to_file "Hosts configuration" "app ${install_app_name}" "${here_etc_host_conf}" ${file_host_host_conf}


	big_step_display "Setup Mod-Security"

	sudo_execute_command "Enable recommended modsecurity configuration" "cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf"
	sudo_write_file "${here_modsecurity_conf}" "${file_modsecurity_modsecurity_conf}"
	sudo_write_file "${here_modsecurity_ignores}" "${file_modsecurity_ignore_conf}"

	# Download 2.5.5 version of the modsecurities core rules
	pushd /tmp
		sudo_execute_command "Download core ruleset" "wget http://downloads.sourceforge.net/project/mod-security/modsecurity-crs/0-CURRENT/modsecurity-crs_2.2.5.tar.gz"
		sudo_execute_command "Unpacking the core ruleset" "tar -zxvf modsecurity-crs_2.2.5.tar.gz"
		sudo_execute_command "Copy core ruleset to destination" "cp -R modsecurity-crs_2.2.5/* /etc/modsecurity/"
		sudo_execute_command "Clean up core ruleset download" "rm -r modsecurity-crs_2.2.5*"
		sudo_execute_command "Activate core ruleset" "cp /etc/modsecurity/modsecurity_crs_10_setup.conf.example  /etc/modsecurity/modsecurity_crs_10_setup.conf"
	popd

	pushd /etc/modsecurity/base_rules
		for f in *
			do 
				sudo ln -s /etc/modsecurity/base_rules/$f /etc/modsecurity/activated_rules/$f
			done
	popd

	sudo_backup_file ${file_apache2_mods_available_modsecurity_conf}
	sudo_write_file "${here_apache_mods_available_modsecurity}" "${file_apache2_mods_available_modsecurity_conf}"
	sudo_execute_command "Enable mod-security" "a2enmod mod-security"


	big_step_display "Setup for Mod-Evasive"

	sudo_execute_command "Create mod-evasive logdir" "mkdir /var/log/mod_evasive"
	sudo_execute_command "Set owner of mod-evasive logdir" "chown www-data:www-data /var/log/mod_evasive/"
	sudo_write_file "${here_apache_mods_available_evasive}" "${file_apache2_mods_available_modevasive_conf}"
	sudo_execute_command "Enable Mod-evasive" "a2enmod mod-evasive"

	# After all restart apache server
	sudo_execute_command "Restart Apache server" "service apache2 restart"
}


function notes_appendix()
{

appendix_message=$(cat <<EOF

That's it. You should reboot now! After that you can point your browser to
${server_url} and will find an instance of ${install_app_name} up and running.
You can login into the application with:

o username: ${install_app_std_username} 
o password: ${install_app_std_pwd}

If you have installed the security packages you should regularly check for mail
in "/var/mail/root". You should also check your logs from time to time using "logwatch".

EOF
)
	
	meta_step_display "Final notes"
	display_step_help "${appendix_message}"
}

## Function calls

# Preparations
# ----------------------o


welcome_user
check_who_is_user
check_unattended_setup

# Install the system:
# ----------------------o

install_basics_gems_and_repos
configure_apache_server
configure_postgresql_database
configure_app_instance

if [ ${do_backup_setup} == "on" ]
then
	setup_backup_strategy 
fi

# Prepare security:
# ----------------------o

if [ ${do_security_setup} == "on" ]
then
	harden_the_system
fi

# Appendix
# ----------------------o

notes_appendix

exit 0
