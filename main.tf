data "archive_file" "cron" {
  type        = "zip"
  source_dir  = "functions"
  output_path = "functions.zip"
}

resource "google_storage_bucket" "functions" {
  name          = "${var.project_id}-functions"
  location      = "US-CENTRAL1"
  project       = var.project_id
  storage_class = "REGIONAL"
}

resource "google_storage_bucket_object" "cron" {
  name   = "cron-${data.archive_file.cron.output_md5}.zip"
  bucket = google_storage_bucket.functions.name
  source = data.archive_file.cron.output_path
}

resource "google_cloudfunctions_function" "function" {
  name                  = "sample"
  description           = "Cloud Functions"
  runtime               = "python38"
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.functions.name
  source_archive_object = google_storage_bucket_object.cron.name
  entry_point           = "main"
  project               = var.project_id
  region                = "us-central1"
  trigger_http          = true
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}
