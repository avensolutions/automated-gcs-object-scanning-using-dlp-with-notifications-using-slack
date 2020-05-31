import base64
import google.cloud.dlp

def send_slack_notification(message):
	import urllib.request, json
	data = {"text": message}
	req = urllib.request.Request("${slack_webhook_url}", headers={"Content-type": "application/json"}, data=bytes(json.dumps(data),encoding="utf8"), method="POST")
	res = urllib.request.urlopen(req)
	if res.status != 200:
		raise RuntimeError("[%s] : %s" % (str(res.status), res.read().decode("utf-8")))

def evaluate_dlp_results(event, context):
	try:
		dlp = google.cloud.dlp.DlpServiceClient()
		dlp_scan_job = event['attributes']['DlpJobName']
		jobState = 0
		while jobState < 3 :	
			job = dlp.get_dlp_job(dlp_scan_job)
			jobState = job.state
		inspectDetails = job.inspect_details
		url = inspectDetails.requested_options.job_config.storage_config.cloud_storage_options.file_set.url
		info_type_stats = inspectDetails.result.info_type_stats
		results = []
		for i in info_type_stats:
			detection = "%s [%d]" % (i.info_type.name, i.count)
			results.append(detection)
		if len(results) > 0:
			message = "*Sensitive Data Detected*: `%s %s` " % (url, str(results))
			send_slack_notification(message)
	except Exception as e:
		print(str(e))