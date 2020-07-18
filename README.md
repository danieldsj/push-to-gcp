# push-to-gcp
BASH scripts that can be used to bootstrap small projects that can be tested, built, and deployed to Google Cloud Platform with a Git push operation.

## Requirements
* Cloud SDK must be installed.
* You must authenticate using the `gcloud` command.
* You must set a project using the `gcloud` command.
* You must initialize the git repository.

## Usage
```
cloudfunctions-python37.sh <FRIENDLY_NAME>
```
or
```
cloudrun.sh <FRIENDLY_NAME>
```

## Output
### cloudfunctions-python37.sh
Example usage and output:
```
$ ./cloudfunctions-python37.sh funky37
Checking arguments.
Checking for presence Cloud SDK.
Checking if user is authenticated.
Checking if project is set.
Checking if present working directory is a Git repository.
Adding permissions to default Cloud Build service account.
Updated IAM policy for project [myproject].
bindings:
- members:
  - serviceAccount:640236124051@cloudbuild.gserviceaccount.com
  role: roles/cloudbuild.builds.builder
- members:
  - serviceAccount:service-640236124051@gcp-sa-cloudbuild.iam.gserviceaccount.com
  role: roles/cloudbuild.serviceAgent
- members:
  - serviceAccount:640236124051@cloudbuild.gserviceaccount.com
  role: roles/cloudfunctions.admin
- members:
  - serviceAccount:service-640236124051@gcf-admin-robot.iam.gserviceaccount.com
  role: roles/cloudfunctions.serviceAgent
- members:
  - serviceAccount:service-640236124051@gcp-sa-cloudscheduler.iam.gserviceaccount.com
  role: roles/cloudscheduler.serviceAgent
- members:
  - serviceAccount:640236124051-compute@developer.gserviceaccount.com
  - serviceAccount:640236124051@cloudservices.gserviceaccount.com
  - serviceAccount:myproject@appspot.gserviceaccount.com
  - serviceAccount:service-640236124051@containerregistry.iam.gserviceaccount.com
  role: roles/editor
- members:
  - user:danieldsj@gmail.com
  role: roles/owner
- members:
  - serviceAccount:640236124051@cloudbuild.gserviceaccount.com
  role: roles/run.admin
- members:
  - serviceAccount:service-640236124051@serverless-robot-prod.iam.gserviceaccount.com
  role: roles/run.serviceAgent
etag: BwWqtouFFg4=
version: 1
Updated IAM policy for serviceAccount [640236124051-compute@developer.gserviceaccount.com].
bindings:
- members:
  - serviceAccount:640236124051@cloudbuild.gserviceaccount.com
  role: roles/iam.serviceAccountUser
etag: BwWqtoukryw=
version: 1
Creating a Google Cloud Source repository.
Created [funky37].
WARNING: You may be billed for this repository. See https://cloud.google.com/source-repositories/docs/pricing for details.
Adding Google Cloud Source repository as remote to local Git repository.
Creating build trigger for when code is pushed to master.
Created [https://cloudbuild.googleapis.com/v1/projects/myproject/triggers/59488aeb-5e4e-48c0-9016-2940b643c2fd].
NAME     CREATE_TIME                STATUS
trigger  2020-07-18T12:38:11+00:00
Generating sample main.py file.
Generating sample test_main.py file.
Generating sample requirements.txt file.
Generating sample cloudbuild.yaml file.
Operation complete. To deploy to Google Cloud Functions, we recommend doing the following commands...
  git status
  git add .
  git commit -m 'First commmit.'
  git push google master
 
To get the URL of your service, we recommend waiting a moment, and running the command...
  gcloud functions list --format='value(httpsTrigger.url)' --filter='entryPoint=funky37'
```
Output of subsequent commands:
```
$ git add .
$ git commit -m 'First commit.'
[master 5d7715e] First commit.
 4 files changed, 5 insertions(+), 5 deletions(-)
$ git push google master
Enumerating objects: 51, done.
Counting objects: 100% (51/51), done.
Delta compression using up to 8 threads
Compressing objects: 100% (47/47), done.
Writing objects: 100% (51/51), 9.00 KiB | 1.29 MiB/s, done.
Total 51 (delta 26), reused 0 (delta 0)
remote: Resolving deltas: 100% (26/26)
To https://source.developers.google.com/p/myproject/r/funky37
 * [new branch]      master -> master
$ gcloud functions list --format='value(httpsTrigger.url)' --filter='entryPoint=funky37'
https://us-central1-myproject.cloudfunctions.net/funky37
```
