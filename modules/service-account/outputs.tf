
/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "email" {
  description = "Service account email"
  value       = google_service_account.sa.email
}

output "iam_email" {
  description = "IAM format service account email"
  value       = google_service_account.sa.member
}

output "id" {
  description = "Service account id in the format 'projects/{{project}}/serviceAccounts/{{email}}'"
  value       = google_service_account.sa.id
}

output "env_vars" {
  description = "Exported environment variables"
  value = { "SERVICE_ACCOUNT_EMAIL" : google_service_account.sa.email,
  "SERVICE_ACCOUNT_IAM_EMAIL" : google_service_account.sa.member }
}
