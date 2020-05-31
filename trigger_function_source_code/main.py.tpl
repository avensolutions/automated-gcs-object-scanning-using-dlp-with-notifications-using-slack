def inspect_gcs_file(project, bucket, filename, topic_id, subscription_id,
                     min_likelihood, max_findings=None, timeout=300):
    import google.cloud.dlp
    dlp = google.cloud.dlp.DlpServiceClient()

    info_types = [{"name": info_type} for info_type in 
    ["CREDIT_CARD_NUMBER", "AUSTRALIA_TAX_FILE_NUMBER", "EMAIL_ADDRESS", "ETHNIC_GROUP", "FIRST_NAME", "LAST_NAME", "GCP_CREDENTIALS", "PHONE_NUMBER"]]

	# create inspect config
    inspect_config = {
        'info_types': info_types,
        'min_likelihood': min_likelihood,
        'limits': {'max_findings_per_request': max_findings},
    }

	# create storage config
    url = 'gs://{}/{}'.format(bucket, filename)
    storage_config = {
        'cloud_storage_options': {
            'file_set': {'url': url}
        }
    }

	# specify topic for DLP results
    parent = dlp.project_path(project)
    actions = [{
        'pub_sub': {'topic': '{}/topics/{}'.format(parent, topic_id)}
    }]

	# create inspect_job object
    inspect_job = {
        'inspect_config': inspect_config,
        'storage_config': storage_config,
        'actions': actions,
    }

	# invoke DLP job
    operation = dlp.create_dlp_job(parent, inspect_job=inspect_job)

    # log message
    print("New object created [%s], DLP scan initiated [%s]" % (url, operation.name))
	
def trigger_dlp_scan(event, context):
    inspect_gcs_file(
		"${project}", event["bucket"], event["name"],
		"${topic}", "${subscription}", "${min_likelihood}"
	)