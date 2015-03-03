#!/bin/bash
# Script to List, Create, Delete Rackspace Cloud Server Images
# Requires jq (http://stedolan.github.io/jq/download/)

# Test if jq already installed, else install it
command -v jq >/dev/null 2>&1 || {
	echo "Installing jq."
	brew install jq
	echo "jq installed."
}

# Set date as variable
DATE=$(date '+%Y-%m-%d')

# Set credentials
. ./set-credentials.sh

# Import set endpoint function
. ./set-endpoint.sh

# Only one endpoint needed for this task
setendpoint cloudServersOpenStack

# Pause
function pause(){
	read -p "Press any key to continue..."
	echo
}

# Invalid Selection
function invalidSelection(){
	tput setaf 1; echo "Invalid Selection!" && tput sgr0
	echo
}

# Menu
function choiceMenu(){
	# tput rev 
	tput smul 
	echo Menu
	echo 1. List Server Images
	echo 2. Create Server Images
	echo 3. Delete Server Images
	echo Q. Quit
	echo
	read -r -p "Menu selection #: " menuSelection
	tput sgr0

	case $menuSelection in
		1)
			listImages
		;;
		2)
			createImage
		;;
		3)
			deleteImage
		;;
		q)
			echo "Bye!"
			exit 0
		;;
		Q)
			echo "Bye!"
			exit 0
		;;
		*)
			echo
			tput setaf 1; echo "Invalid selection!" && tput sgr0
			echo
		;;
	esac
}

# List server images
function listImages(){
	# Get details for all server images available
	IMAGEDETAILS=$(curl -sX GET $publicURL/images?type=SNAPSHOT\&status=ACTIVE -H "X-Auth-Token: $TOKEN")
	# echo $IMAGEDETAILS | jq .

	# Create list of images
	IMAGELIST=$(echo "$IMAGEDETAILS" | jq '.images | .[]  | .name ' | cut -d '"' -f 2 | nl -s ". ")

	echo
	tput smul; echo "List of Server Images:" && tput sgr0
	echo "$IMAGELIST"
	echo

	# # Work on displaying date image was created next to the image name
	# NAMELIST=$(echo "$IMAGELIST" | grep -w 1 | cut -d '.' -f 2 | cut -c 2-)
	# echo $NAMELIST

	# # Get image details from name
	# MOREIMAGEDETAILS=$(curl -sX GET $publicURL/images?type=SNAPSHOT --data-urlencode "name=$NAMELIST" -H "X-Auth-Token: $TOKEN")
	# IMAGEID=$(echo $MOREIMAGEDETAILS | jq '.images | .[]  | .id ' | cut -d '"' -f 2)
	# echo "$IMAGEID" | nl | grep -w 1 | cut -f 2

	# IMAGEDATE=$(curl -sX GET $publicURL/images/$IMAGEID -H "X-Auth-Token: $TOKEN" | jq '.image | .created ' | cut -d '"' -f 2)
	# echo "$IMAGEDATE"
	# pause
}

# Create server images
function createImage(){
	# Get server details
	SERVERS=$(curl -sX GET $publicURL/servers/detail -H "X-Auth-Token: $TOKEN")
	# echo "$SERVERS" | jq . 

	# SERVERNAME=$(echo "$SERVERS" | grep -w name | cut -d '"' -f 4)

	# Use jq tool to parse out server names
	SERVERNAME=$(echo "$SERVERS" | jq '.servers | .[] | .name' | cut -d '"' -f 2)
	# echo "$SERVERNAME"

	# Use jq tool to parse out server IDs
	SERVERIDS=$(echo "$SERVERS" | jq '.servers | .[] | .id' | cut -d '"' -f 2)
	# echo "$SERVERIDS"

	NUMSERVERS=$(echo "$SERVERIDS" | wc -l)
	# echo $NUMSERVERS

	# Zero servers
	if [ "$NUMSERVERS" -eq "0" ]; then
		tput setaf 1; echo "No servers found or error getting server data." && tput sgr0
		exit 1
	fi

	# One server
	if [ "$NUMSERVERS" -eq "1" ]; then
		# Create server image
		curl -sX POST $publicURL/servers/$SERVERIDS/action \
		-H "X-Auth-Token: $TOKEN" \
		-H "Content-Type: application/json" \
		-H "Accept: application/json" \
		-d '{"createImage": {"name": "'"$SERVERNAME"' '"$DATE"'"}}' \
		-i
	fi

	# More than one server
	if [ "$NUMSERVERS" -gt "1" ]; then
		
		# Create numbered server list
		SERVERLIST=$(echo "$SERVERNAME" | nl -s ". ")
		echo
		tput smul; echo "List of Servers:" && tput sgr0
		echo "$SERVERLIST"
		echo
		tput smul; read -r -p "Select Server # to Image, 0 to Image All, Q to Quit: " imageSelection && tput sgr0
		echo

		# Quit
		if [[ $imageSelection =~ ^([qQ])$ ]]; then
			return 1
		fi

		# Invalid
		if [[ -z $imageSelection ]]; then
			invalidSelection
			return 1
		fi

		# echo $imageSelection

		# Image All Servers
		if [ "$imageSelection" -eq "0" ]; then

			START=1
			for (( COUNT=$START; COUNT<=$NUMSERVERS; COUNT++ ))
			do
				# echo \#$COUNT

				# Process one server at a time
				SERVERID=$(echo "$SERVERIDS" | nl | grep -w $COUNT | cut -f 2)
				# echo Server ID: "$SERVERID"

				# Get server details
				SERVERDETAILS=$(curl -sX GET $publicURL/servers/$SERVERID -H "X-Auth-Token: $TOKEN")
				# echo "$SERVERDETAILS" | jq . 

				# Get server name
				SERVERNAME=$(echo "$SERVERDETAILS" | jq '.server | .name ' | cut -d '"' -f 2)
				echo "Creating image for "$SERVERNAME

				# Create server image
				IMAGECREATE=$(curl -sX POST $publicURL/servers/$SERVERID/action \
					-H "X-Auth-Token: $TOKEN" \
					-H "Content-Type: application/json" \
					-H "Accept: application/json" \
					-d '{"createImage": {"name": "'"$SERVERNAME"' '"$DATE"'"}}' \
					-i)

				# echo "$IMAGECREATE"

				if echo "$IMAGECREATE" | grep -q "202 Accepted"; then
					tput setaf 2; echo "Image successfully created." && tput sgr0
					echo
				else
					tput setaf 1; echo "Error creating image:"
					echo "$IMAGECREATE" && tput sgr0
					echo
				fi
			done
		fi

		if [ "$imageSelection" -gt "0" ]; then

			# Image just one server
			SERVERID=$(echo "$SERVERIDS" | nl | grep -w $imageSelection | cut -f 2)
			# echo Server ID: "$SERVERID"

			if [[ -z $SERVERID ]]; then
				invalidSelection
				return 1
			fi

			# Get server details
			SERVERDETAILS=$(curl -sX GET $publicURL/servers/$SERVERID -H "X-Auth-Token: $TOKEN")
			# echo "$SERVERDETAILS" | jq . 

			# Get server name
			SERVERNAME=$(echo "$SERVERDETAILS" | jq '.server | .name ' | cut -d '"' -f 2)
			echo "Creating image for "$SERVERNAME

			# Create server image
			IMAGECREATE=$(curl -sX POST $publicURL/servers/$SERVERID/action \
			  -H "X-Auth-Token: $TOKEN" \
			  -H "Content-Type: application/json" \
			  -H "Accept: application/json" \
			  -d '{"createImage": {"name": "'"$SERVERNAME"' '"$DATE"'"}}' \
			  -i)

			if echo "$IMAGECREATE" | grep -q "202 Accepted"; then
				tput setaf 2; echo "Image successfully created." && tput sgr0
				echo
			else
				tput setaf 1; echo "Error creating image:"
				echo "$IMAGECREATE" && tput sgr0
				echo
			fi
		fi
	fi
	# echo "$SERVERNAME" "$SERVERID"
}

# Delete server images
function deleteImage(){
	listImages
	tput smul; read -r -p "Select Image # to Delete or Q to Quit: " deleteSelection && tput sgr0
	echo

	# Quit
	if [[ $deleteSelection =~ ^([qQ])$ ]]; then
		return 1
	fi

	# Invalid
	if [[ -z $deleteSelection ]]; then
		invalidSelection
		return 1
	fi

	# Select image to delete
	DELETEIMAGENAME=$(echo "$IMAGELIST" | grep -w $deleteSelection | cut -d '.' -f 2 | cut -c 2-)

	if [[ -z $DELETEIMAGENAME ]]; then
	  invalidSelection
	  return 1
	fi

	echo "Image name: "$DELETEIMAGENAME

	# Get image details from name
	DELETEIMAGEDETAILS=$(curl -sGX GET $publicURL/images?type=SNAPSHOT --data-urlencode "name=$DELETEIMAGENAME" -H "X-Auth-Token: $TOKEN")
	# IMAGEID=$(echo "$IMAGEDETAILS" | grep )
	# echo $DELETEIMAGEDETAILS | jq .

	# Get image ID from details
	DELETEIMAGEID=$(echo "$DELETEIMAGEDETAILS" | jq '.images | .[]  | .id ' | cut -d '"' -f 2)
	# echo "Image ID: "$DELETEIMAGEID

	# Delete image
	DELETEIMAGE=$(curl -isX DELETE $publicURL/images/$DELETEIMAGEID -H "X-Auth-Token: $TOKEN")
	if echo "$DELETEIMAGE" | grep -q "204 No Content"; then
		tput setaf 2; echo $DELETEIMAGENAME" successfully deleted." && tput sgr0
		echo
	else
		tput setaf 1; echo "Error deleting image:"
		echo "$DELETEIMAGE" && tput sgr0
		echo
	fi
}

# Loop the Menu
while :
do
	# Call the menu
	choiceMenu
done