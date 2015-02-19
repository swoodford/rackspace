#!/bin/bash
# Sets Public URL for Rackspace service Endpoint
# TENANT and REGION must be specified in set-credentials.sh!

function setendpoint(){
	# cloudFilesCDN
	if [ $1 = "cloudFilesCDN" ]; then
		publicURL="https://cdn5.clouddrive.com/v1/MossoCloudFS_$TENANT"
	fi
	# cloudFiles
	if [ $1 = "cloudFiles" ]; then
		publicURL="https://storage101.$REGION3.clouddrive.com/v1/MossoCloudFS_$TENANT"
	fi
	# cloudBlockStorage
	if [ $1 = "cloudBlockStorage" ]; then
		publicURL="https://$REGION.blockstorage.api.rackspacecloud.com/v1/$TENANT"
	fi
	# cloudLoadBalancers
	if [ $1 = "cloudLoadBalancers" ]; then
		publicURL="https://$REGION.loadbalancers.api.rackspacecloud.com/v1.0/$TENANT"
	fi
	# cloudDatabases
	if [ $1 = "cloudDatabases" ]; then
		publicURL="https://$REGION.databases.api.rackspacecloud.com/v1.0/$TENANT"
	fi
	# cloudBackup
	if [ $1 = "cloudBackup" ]; then
		publicURL="https://$REGION.backup.api.rackspacecloud.com/v1.0/$TENANT"
	fi
	# cloudImages
	if [ $1 = "cloudImages" ]; then
		publicURL="https://$REGION.images.api.rackspacecloud.com/v2"
	fi
	# cloudDNS
	if [ $1 = "cloudDNS" ]; then
		publicURL="https://dns.api.rackspacecloud.com/v1.0/$TENANT"
	fi
	# cloudServersOpenStack
	if [ $1 = "cloudServersOpenStack" ]; then
		publicURL="https://$REGION.servers.api.rackspacecloud.com/v2/$TENANT"
	fi
	# cloudQueues
	if [ $1 = "cloudQueues" ]; then
		publicURL="https://$REGION.queues.api.rackspacecloud.com/v1/$TENANT"
	fi
	# cloudBigData
	if [ $1 = "cloudBigData" ]; then
		publicURL="https://$REGION.bigdata.api.rackspacecloud.com/v1.0/$TENANT"
	fi
	# cloudOrchestration
	if [ $1 = "cloudOrchestration" ]; then
		publicURL="https://$REGION.orchestration.api.rackspacecloud.com/v1/$TENANT"
	fi
	# autoscale
	if [ $1 = "autoscale" ]; then
		publicURL="https://$REGION.autoscale.api.rackspacecloud.com/v1.0/$TENANT"
	fi
	# cloudMetrics
	if [ $1 = "cloudMetrics" ]; then
		publicURL="https://global.metrics.api.rackspacecloud.com/v2.0/$TENANT"
	fi
	# cloudFeeds
	if [ $1 = "cloudFeeds" ]; then
		publicURL="https://$REGION.feeds.api.rackspacecloud.com/$TENANT"
	fi
	# cloudMonitoring
	if [ $1 = "cloudMonitoring" ]; then
		publicURL="https://monitoring.api.rackspacecloud.com/v1.0/$TENANT"
	fi
}

# Export the Endpoint URL
ENDPOINT="$publicURL"
export ENDPOINT="$publicURL"
echo $ENDPOINT