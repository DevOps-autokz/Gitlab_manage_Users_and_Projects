#!/bin/bash
[ -f .env ] && . .env
# uncomment and fill variables below,
# or insert them in .env file
# token=### insert your own gitlab token
# GITLAB_URL=### insert Gitlab server's address (e.g. https://gitlab.com or your own one)
PASSWORD="change@me"

# Set Color Variables and Functions
green='\e[32m'
blue='\e[94m'
red='\e[91m'
cyan='\e[36m'
light_cyan='\e[96m'
clear='\e[0m'

ColorGreen(){
	echo -ne $green$1$clear
}
ColorBlue(){
	echo -ne $blue$1$clear
}
ColorRed(){
	echo -ne $red$1$clear
}
ColorCyan(){
	echo -ne $cyan$1$clear
}
ColorLightCyan(){
	echo -ne $light_cyan$1$clear
}

### ------------------   MAIN FUNCTIONS SECTION ---------------- 
# Lsit all users:
function list_users {
curl -s --request GET --header "PRIVATE-TOKEN: ${token}" ${GITLAB_URL}/api/v4/users | jq -r '.[].name'
}

# Create simple user:
function create_simple_user {
read -p $"$(ColorLightCyan 'Please, enter Full Name (e.g. John Brown): ')" NAME
[[ -z ${NAME} ]]  && { echo -e $(ColorRed 'Please, start over and enter Full Name') ; exit 1 ; }

read -p $"$(ColorLightCyan 'Please, enter the username (e.g. john-b): ')" USERNAME
[[ -z ${USERNAME} ]]  && { echo -e $(ColorRed 'Please, start over and enter the username') ; exit 1 ; }

read -p $"$(ColorLightCyan 'Please, enter e-mail: ')" EMAIL
[[ -z ${EMAIL} ]]  && { echo -e $(ColorRed 'Please, start over and enter e-mail ') ; exit 1 ; }

curl -s --request POST -d "name=$NAME&username=$USERNAME&password=${PASSWORD}&email=$EMAIL&commit_email=$EMAIL&theme_id=11&color_scheme_id=2" --header "PRIVATE-TOKEN: ${token}" ${GITLAB_URL}/api/v4/users  && \
echo -e $(ColorLightCyan "user $USERNAME has been successfully created")
}

# Choose a user from the list:
function choose_user { 
USERS=($(curl -s --request GET --header "PRIVATE-TOKEN: ${token}" "${GITLAB_URL}/api/v4/users" | jq -r '.[].username')) && \
	read -p "$(
	f=0
        for user in "${USERS[@]}" ;  do echo "$((++f)): ${user}" ; done
             echo -ne $(ColorGreen 'Please type a number > ')
            )" selection
user_name="${USERS[$((selection-1))]}" && \
echo -e $(ColorLightCyan "You selected $user_name")
USER_ID=$(curl -s  --request GET --header "PRIVATE-TOKEN: ${token}" "${GITLAB_URL}/api/v4/users?username=${user_name}" | jq -r  '.[].id') 
}

# Choose a project:
function choose_project { 
PROJECTS=($(curl -s --request GET --header "PRIVATE-TOKEN: ${token}" "${GITLAB_URL}/api/v4/projects?per_page=500" | jq -r '.[].path')) && \
	read -p "$(
	f=0
        for project in "${PROJECTS[@]}" ;  do echo "$((++f)): ${project}" ; done
             echo -ne $(ColorGreen 'Please type a number > ')
            )" selection
project_name="${PROJECTS[$((selection-1))]}" && \
echo -e $(ColorLightCyan "You selected $project_name")
PROJECT_ID=$(curl -s --header "PRIVATE-TOKEN: ${token}" "$GITLAB_URL/api/v4/projects?search=${project_name}"  | jq '.[0].id')
}

# Choose a role:
function choose_role {
	# Define the list of roles:
	roles=('Developer' 'Maintainer' 'Owner')
# List the roles:
echo -e $(ColorGreen "Select a role:")
for i in "${!roles[@]}"; do
  echo -e $(ColorCyan "$i) ${roles[$i]}")
done
# Prompt the role for input
read -p "$(ColorGreen 'Enter the number corresponding to your selection:' )" selection
# Determine the selected role and save the corresponding number to a variable
if [[ $selection -eq 0 ]]; then
  ACCESS_LEVEL=30
  ROLE='Developer'
  echo -e $(ColorCyan "Selected role: Developer")
elif [[ $selection -eq 1 ]]; then
  ACCESS_LEVEL=40
  ROLE='Maintainer'
  echo -e $(ColorLightCyan "Selected role: Maintainer")
elif [[ $selection -eq 2 ]]; then
  ACCESS_LEVEL=50
  ROLE='Owner'
  echo -e $(ColorLightCyan "Selected role: Owner")
else
  echo -e $(ColorRed "Invalid selection")
  exit 1
fi
}

# Set access level to user:
function change_access_level {
curl --request POST -d "user_id=$USER_ID&access_level=$ACCESS_LEVEL" --header "PRIVATE-TOKEN: ${token}" ${GITLAB_URL}/api/v4/projects/$PROJECT_ID/members  && \
echo -e $(ColorLightCyan "User $user_name has been granted Access Level: $ROLE to project: $project_name")
}

# Delete user:
function delete_user {
	curl -s --request DELETE --header "PRIVATE-TOKEN: ${token}" "${GITLAB_URL}/api/v4/users/$USER_ID" && \
	echo -e $(ColorRed "User ${user_name} has been deleted")
}

# List groups:
function list_groups {
curl -s --request GET --header "PRIVATE-TOKEN: ${token}" ${GITLAB_URL}/api/v4/groups | jq -r '.[].full_name'
}

# Create new project:
# Will be available in next release


### ----------------------  SELECTION MENU SECTION -------------------------

#### Selection Menu 
PS3=$(ColorGreen 'Press Enter to continue: ')
while :
do
    clear
    options=( \
    	"List all users ${opts[1]}" \
	"Add user ${opts[2]}" \
	"Delete user ${opts[3]}" \
	"List groups ${opts[4]}" \
	"Change role ${opts[5]}" \
	"List projects ${opts[6]}" \
	"Create new project ${opts[7]}" \
	"Exit")
    select opt in "${options[@]}"
    do
        case $opt in
            "List all users ${opts[1]}")
		list_users
                ;;
            "Add user ${opts[2]}")
		create_simple_user
                ;;
            "Delete user ${opts[3]}")
		[ -n "$USER_ID" ] && unset USER_ID
		choose_user
		delete_user
                ;;
            "List groups ${opts[4]}")
                list_groups
                ;;
            "Change role ${opts[5]}")
		choose_user
                choose_project
		choose_role
		change_access_level
		sleep 5 && break
                ;;
            "List projects ${opts[6]}")
		echo -e $(ColorCyan 'Will be available in next release')
                sleep 3 && break
                ;;
             "Create new project ${opts[7]}")
                echo -e $(ColorCyan 'Will be available in next release') 
                sleep 3 && break
                ;;
             "Exit")
                break 2
                ;;
            *) printf '%s\n' 'invalid option';;
        esac
    done
done
