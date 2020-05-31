variable "region" {}
variable "project" {}
variable "topic" {}
variable "subscription" {}
variable "resource" {}
variable "event_type" {}
variable "min_likelihood" {}
/* valid values include:
	VERY_UNLIKELY
	UNLIKELY	
	POSSIBLE
	LIKELY	
	VERY_LIKELY
*/
variable "slack_webhook_url" {}
variable "source_archive_bucket" {}

