#!/bin/bash
# Work with Rackspace Load Balancers
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

# Pause
function pause(){
	read -p "Press any key to continue..."
	echo
}

# Menu
function choiceMenu(){
	tput smul
	echo Menu
	echo 1. Create new Load Balancer
	echo 2. Add Nodes to Existing Load Balancer
	echo 3. Setup Monitoring on Existing Load Balancer
	echo 4. List Load Balancers
	echo Q. Quit
	echo
	read -r -p "Menu selection #: " menuSelection
	tput sgr0

	case $menuSelection in
		1)
			createLB
		;;
		2)
			addNodes
		;;
		3)
			monitorLB
		;;
		4)
			getLBdata
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

# Create new LB
function createLB(){
	# Set endpoint for this task
	setendpoint cloudLoadBalancers

	echo
	echo "================================================================="
	echo "                Create Rackspace Load Balancer"
	echo "================================================================="
	echo

	read -r -p "Enter Load Balancer Name (Client-Project): " LBNAME
	if [[ -z $LBNAME ]]; then
		tput setaf 1; echo "Invalid Name!" && tput sgr0
		return 1
	fi

	# HTTPS Option
	read -r -p "Listen on HTTPS? (y/n) " SECURE
	if [[ $SECURE =~ ^([yY][eE][sS]|[yY])$ ]]; then
		PORT="443"
		PROTO="HTTPS"
		HTTPSRD="true"
	else
		PORT="80"
		PROTO="HTTP"
		HTTPSRD="false"
	fi
	echo
	echo
	echo "================================================================="
	echo "                  Creating Load Balancer..."
	echo "================================================================="
	# HTTP LB
	# -d '{"loadBalancer":{"name":"a-new-loadbalancer","port":80,"protocol":"HTTP","algorithm":"LEAST_CONNECTIONS","timeout":30,"connectionThrottle":{"maxConnections":100},"virtualIps":[{"type":"PUBLIC"}]}}' \

	# Connection Throttling cannot be set when creating a new LB
	# "connectionThrottle":{"maxConnections":100},

	# Create Load Balancer
	CREATETHELB=$(curl -sX POST $publicURL/loadbalancers \
	  -H "X-Auth-Token: $TOKEN" \
	  -H "Content-Type: application/json" \
	  -H "Accept: application/json" \
	  -d '{"loadBalancer":{"name":"'"$LBNAME"'","port":"'"$PORT"'","protocol":"'"$PROTO"'","httpsRedirect":"'"$HTTPSRD"'","algorithm":"LEAST_CONNECTIONS","virtualIps":[{"type":"PUBLIC"}],"connectionThrottle":{"maxConnections":100,"minConnections":1,"maxConnectionRate":50,"rateInterval":60}}}')

	echo $CREATETHELB | jq .
	echo

	LBID=$(echo "$CREATETHELB" | jq '.loadBalancer | .id' | cut -d '"' -f 2)
	echo Load Balancer ID: $LBID

	# RESPONSE2=$(curl -sX PUT $publicURL/loadbalancers/$LBID/connectionthrottle \
	#   -H "X-Auth-Token: $TOKEN" \
	#   -H "Content-Type: application/json" \
	#   -H "Accept: application/json" \
	#   -d '{"connectionThrottle":{"maxConnections":100,"minConnections":1,"maxConnectionRate":50,"rateInterval":60}}')
	# echo $RESPONSE2 | jq .
	echo
	echo "================================================================="
	echo "              Completed!  Load Balancer ID: "$LBID
	echo "================================================================="
	echo
	echo
	echo "================================================================="
	read -r -p "              Add Nodes to Load Balancer? (y/n) " NODES
	echo "================================================================="
	echo
	if [[ $NODES =~ ^([yY][eE][sS]|[yY])$ ]]; then
		addNodes
	fi
}

# Get LB Data
function getLBdata(){
	# Change endpoint to LB
	setendpoint cloudLoadBalancers

	# Get data on all Load Balancers
	GETLBS=$(curl -sX GET $publicURL/loadbalancers -H "X-Auth-Token: $TOKEN" -H "Accept: application/json" | python -m json.tool)
	echo $GETLBS | jq .
}

# Select a LB
function selectLB(){
	# Change endpoint to LB
	setendpoint cloudLoadBalancers

	function oneLB(){
		LBNAME=$(echo "$GETLBS" | jq '.loadBalancer | .[] | .name' | cut -d '"' -f 2 | nl)
		LBID=$(echo "$GETLBS" | jq '.loadBalancer | .[] | .id' | nl)
		echo "$LBNAME"
		echo "$LBID"
		pause
	}

	function multipleLBs(){
		LBNAMES=$(echo "$GETLBS" | jq '.loadBalancers | .[] | .name' | cut -d '"' -f 2 | nl)
		LBIDS=$(echo "$GETLBS" | jq '.loadBalancers | .[] | .id' | nl)
		LBID=$(echo "$GETLBS" | jq '.loadBalancers | .[] | .id') # | cut -d '"' -f 2)
		echo
		echo "$LBNAMES"
		echo "$LBIDS"
		echo
		read -r -p "Select Load Balancer #: " selectedLB
		# FixMe: How is a LB selected?
		pause
	}

	# FixMe: Test needs work

	# If we don't have a LBID
	if [[ -z $LBID ]]; then
		# Test for number of loadbalancers
		TESTNUMLBS=$(echo "$GETLBS" | grep -w "loadBalancer")
		if [[ -z $TESTNUMLBS ]]; then
			echo "Multiple LBs"
			multipleLBs
		fi

		TESTNUMLBS=$(echo "$GETLBS" | grep -w "loadBalancers")
		if [[ -z $TESTNUMLBS ]]; then
			echo "One LB"
			oneLB
		fi
	fi
}

function checkLBstatus(){
	# Change endpoint to LB
	setendpoint cloudLoadBalancers

	# Check the Load Balancer Status
	LBSTATUS=$(curl -sX GET $publicURL/loadbalancers/$LBID -H "X-Auth-Token: $TOKEN" -H "Accept: application/json" | jq '.loadBalancer | .status' | cut -d '"' -f 2)
	while [ $LBSTATUS != "ACTIVE" ]; do
		# echo "LB Status: "$LBSTATUS
		echo "Waiting for Load Balancer to become active..."
		sleep 15
		checkLBstatus
	done
}

function addNodes(){
	# Set endpoint for this task
	setendpoint cloudServersOpenStack

	# Get server details
	SERVERS=$(curl -sX GET $publicURL/servers/detail -H "X-Auth-Token: $TOKEN" | python -m json.tool)

	# Use jq tool to parse out names
	SERVERNAME=$(echo "$SERVERS" | jq '.servers | .[] | .name' | cut -d '"' -f 2)
	SERVERIP=$(echo "$SERVERS" | jq '.servers | .[] | .addresses | .private | .[] | .addr' | cut -d '"' -f 2)
	# SERVERID=$(echo "$SERVERS" | jq '.servers | .[] | .id' | cut -d '"' -f 2)

	echo
	echo "Servers:"
	echo "$SERVERNAME" | sort
	echo "IPs:"
	echo "$SERVERIP" | sort
	echo

	# FixMe: How is a server selected?

	pause

	# Check status of LB, wait for BUILD to complete
	# RESPONSE2=$(curl -sX GET $publicURL/loadbalancers/$LBID \
	#   -H "X-Auth-Token: $TOKEN" \
	#   -H "Accept: application/json")

	# function getLBdata(){
	# 	LBSTATUS=$(echo "$RESPONSE2" | jq '.loadBalancer | .status' | cut -d '"' -f 2)
	# 	echo $LBSTATUS
	# 	if $LBSTATUS == "BUILD"; then
	# 		echo "Waiting for Load Balancer to build..."
	# 		sleep 5
	# 		getLBdata
	# 	else
	# 		echo "LB Status: "$LBSTATUS
	# 		break
	# 	fi
	# }

		# Ensure we have the correct Load Balancer ID
		# if [[ -z $LBID ]]; then
		# 	# LBNAME=$(echo "$GETLBS" | grep -w "loadBalancer")
		# 	# echo $LBNAME
		# 	# echo
		# 	# echo
		# 	# read -r -p "Select Load Balancer #: " selectedLB

		# 	# Single LB Case
		# 	# LBID=$(echo "$LBIDS" | jq '.loadBalancer | .id') # | cut -d '"' -f 2)
		# 	# echo "Single LB Case"
		# 	# echo $LBID

		# 	# More than one LB Case
		# 	if [[ -z $LBID ]]; then

		# 	fi

		# 	echo
		# 	# LBID=$(echo "$LBID" | jq '.loadBalancer | .id' | cut -d '"' -f 2)
		# 	echo Load Balancer ID: $LBID
		# fi
	# }

	getLBdata
	selectLB
	checkLBstatus
	echo "LB Status: "$LBSTATUS

	pause

	ADDNODETOLB=$(curl -sX POST $publicURL/loadbalancers/$LBID/nodes \
	  -H "X-Auth-Token: $TOKEN" \
	  -H "Content-Type: application/json" \
	  -H "Accept: application/json" \
	  -d '{"nodes":[{"address":"'"$SERVERIP"'","port":'"$PORT"',"condition":"ENABLED","type":"PRIMARY"}]}')

	echo $ADDNODETOLB | jq .
	echo
}

function monitorLB(){
	echo "LB Monitoring coming soon!"
}

function listLB(){
	echo "List Load Balancers coming soon!"
}

# Loop the Menu
while :
do
	# Call the menu
	choiceMenu
done
