#
# Module Provider
#

provider "google" {
  region = var.region
}

data "google_client_config" "current" {}

#
# Create PubSub Topic
#

resource "google_pubsub_topic" "dlp_scan_topic" {
  name = var.topic
}


#
# Create PubSub Pull Subscription to View Messages
#

resource "google_pubsub_subscription" "pull_sub" {
  name  = "dlp-pull-subscription"
  topic = google_pubsub_topic.dlp_scan_topic.name
}

#
# Render Cloud Function source code template to trigger DLP scan for newly created objects
#

resource "local_file" "trigger_function" {
    content     = templatefile("${path.module}/trigger_function_source_code/main.py.tpl", {
      project = var.project,
      topic = var.topic,
      subscription = var.subscription,
      min_likelihood = var.min_likelihood
      })
    filename = "${path.module}/trigger_function_source_code_rendered/main.py"
}

#
# Create ZIP archive for Cloud Function source code
#

data "archive_file" "gcs_dlp_trigger_function_zip" {
	type = "zip"
	output_path = "${path.module}/gcs_dlp_trigger_function.zip"
	source_dir = "${path.module}/trigger_function_source_code_rendered/"
	depends_on = [
		local_file.trigger_function,
	]    
}

#
# Deploy Cloud Function to Trigger Scan for New Objects
#
 
resource "google_storage_bucket_object" "trigger_source_archive_object" {
	name   = "gcs_dlp_trigger_function.zip"
	bucket = var.source_archive_bucket
	source = "${path.module}/gcs_dlp_trigger_function.zip"
	depends_on = [
		data.archive_file.gcs_dlp_trigger_function_zip,
	]  
}

resource "google_cloudfunctions_function" "trigger_scan_function" {
	name = "gcs-dlp-scan-trigger"
    project =  "gcp-networking-intro"
	runtime = "python37"
	description = "Triggers a DLP scan for new objects being created"
	available_memory_mb = "128"
	timeout = 60
	source_archive_bucket = var.source_archive_bucket
	source_archive_object = google_storage_bucket_object.trigger_source_archive_object.name
	entry_point = "trigger_dlp_scan"
	event_trigger {
		event_type = var.event_type
		resource = var.resource
	}
}

#
# Render Cloud Function source code template to evaluate DLP scan results
#

resource "local_file" "results_function" {
    content     = templatefile("${path.module}/results_function_source_code/main.py.tpl", {
      slack_webhook_url = var.slack_webhook_url
      })
    filename = "${path.module}/results_function_source_code_rendered/main.py"
}

#
# Create ZIP archive for Cloud Function source code
#

data "archive_file" "gcs_dlp_results_function_zip" {
	type = "zip"
	output_path = "${path.module}/gcs_dlp_results_function.zip"
	source_dir = "${path.module}/results_function_source_code_rendered/"
	depends_on = [
		local_file.results_function,
	]  
}

#
# Deploy Cloud Function to Evaluate Scan Results
#
 
resource "google_storage_bucket_object" "results_source_archive_object" {
	name   = "gcs_dlp_results_function.zip"
	bucket = var.source_archive_bucket
	source = "${path.module}/gcs_dlp_results_function.zip"
	depends_on = [
		data.archive_file.gcs_dlp_results_function_zip,
	]  
}

resource "google_cloudfunctions_function" "evaluate_results_function" {
	name = "gcs-dlp-evaluate-results"
    project =  "gcp-networking-intro"
	runtime = "python37"
	description = "Evaluates DLP scan results for new objects being created"
	available_memory_mb = "128"
	timeout = 60
	source_archive_bucket = var.source_archive_bucket
	source_archive_object = google_storage_bucket_object.results_source_archive_object.name
	entry_point = "evaluate_dlp_results"
	event_trigger {
		event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
		resource = google_pubsub_topic.dlp_scan_topic.name
	}
}
