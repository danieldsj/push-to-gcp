# push-to-gcp
BASH scripts that can be used to bootstrap small projects that can be tested, built, and deployed to Google Cloud Platform with a Git push operation.

## Features
* Enables Google Cloud Source Repository API.
* Enables Google Cloud Build API.
* Enables Google Cloud Functions API as needed.
* Enables Google Cloud Run API as needed.
* Adds necessary role bindings to project's Google Build service account.
* Creates a Google Cloud Source Repository.
* Adds the Google Cloud Source Repository as a remote on the local Git repository.
* Creates a Google Cloud Build trigger.  Deploy commands generally use the default App Engine service acccount.
* Generates some sample files:
  * An appropriate cloudbuild.yaml file.
  * For `cloudfunctions-python37.sh` - Several files to support a simple python function that responds with `hello world`.
  * For `cloudrun.sh` - Several files to support a simple Nginx container that hosts an `index.html` file that displays `hello world`.
* Provides instructions on how to push.
* Provides instructions on how to get the URL of what you pushed.
* Defaults to auto-scaling to only one instance to avoid any runaway costs.

## Requirements
* Cloud SDK must be installed.
* You must authenticate using the `gcloud` command.
* You must set a project using the `gcloud` command.
* You must initialize the Git repository.

## Syntax
```
cloudfunctions-python37.sh <FRIENDLY_NAME>
```
or
```
cloudrun.sh <FRIENDLY_NAME>
```

## Cost
Although one of the goals of this projects is to keep costs low, using this script may result in a project that can incure costs. The bash scripts have a bias towards solutions that scale to zero to keep costs as low as possible.

### Cloud Run
Cloud Run [pricing](https://cloud.google.com/run/pricing) is based on CPU, Memory, # of requests, and egress bandwidth. In order to minimize some of the costs, we did the following:
* Set a maximum to `1` [instance](https://cloud.google.com/sdk/gcloud/reference/run/services/update#--max-instances).
* Set instances to `200m` [CPU](https://cloud.google.com/run/docs/configuring/cpu#command-line) (First 180,000 vCPU-seconds free).
* Set instances to `128Mi` of [memory](https://cloud.google.com/sdk/gcloud/reference/run/services/update#--memory) (First 360,000 GiB-seconds free).

### Cloud Function
Cloud Function [pricing](https://cloud.google.com/functions/pricing) is based on the number of invocations, compute time, and egress network traffic. In order to minimize cost, we did the following:
* Set the maximum number of [instances](https://cloud.google.com/sdk/gcloud/reference/functions/deploy#--max-instances) to `1`.
* Set the [memory](https://cloud.google.com/sdk/gcloud/reference/functions/deploy#--memory) to the minmum value of `128mi`. 

### Cloud Storage Repository
Cloud Storage Repository [pricing](https://cloud.google.com/source-repositories/pricing) is based on number of project-users, storage, and egress. Many of these costs are heavily dependent on the nature of the software you are building. Keep in mind that due to the number of projects I created for testing, I was eventually billed for more than 5 project-users in a month.  This was my first charge throughout testing.  This cost may be mitigated by using [creating triggers for GitHub repositories](https://cloud.google.com/sdk/gcloud/reference/beta/builds/triggers/create/github) instead of Google Cloud Platform repositories.

### Cloud Build
Cloud Build [pricing](https://cloud.google.com/cloud-build/pricing) is based on build minutes, and the rates vary depending on what [machine type](https://cloud.google.com/sdk/gcloud/reference/builds/submit#--machine-type) is being used. The machine type used can be defined in the `cloudbuild.yaml`, but defaults to the most cost effective 1 CPU option according to the [documentation](https://cloud.google.com/cloud-build/docs/build-config#options).

## Example Usage
The following is a possible workflow:
1. Create a new Google Cloud Platform project.
2. Open the Cloud Shell.
3. Create a directory with a command similar to `mkdir repo`.
4. Change directory with a command similar to `cd repo`.
5. Initialize the Git repository with `git init`.
6. Download the script with a command similar to the following: `wget https://raw.githubusercontent.com/danieldsj/push-to-gcp/master/cloudfunction-python37.sh`
7. Execute the script with a command similar to the following: `bash cloudfunction-python37.sh funky`

**CAUTION:** Retrieving BASH using curl and piping their contents to BASH is not a best practice but seems to be popular. I encourage you to exercise caution and read the code first.  For convenience here is an example of how it can be done: `curl https://raw.githubusercontent.com/danieldsj/push-to-gcp/master/cloudfunction-python37.sh | bash -s funky` 

## Example Output
### cloudfunctions-python37.sh
Example usage and output:
```
$ curl https://raw.githubusercontent.com/danieldsj/push-to-gcp/master/cloudfunction-python37.sh | bash -s funky
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  4695  100  4695    0     0  78250      0 --:--:-- --:--:-- --:--:-- 78250
Checking arguments.
Checking for presence Cloud SDK.
Checking if user is authenticated.
Checking if project is set.
Your active configuration is: [cloudshell-5272]
Checking if present working directory is a Git repository.
Your active configuration is: [cloudshell-5272]
Enabling Google Cloud Build API.
Operation "operations/acf.35d9c45a-e764-4212-8196-1f512ffd01fe" finished successfully.
Enabling Google Cloud Source Repository API
Operation "operations/acf.383ae49e-c51c-466e-b51c-74ba2260bebd" finished successfully.
Enabling Google Cloud Functions API.
Operation "operations/acf.09d134cd-ab0d-4497-a899-e9d1ad714a09" finished successfully.
Adding permissions to default Cloud Build service account.
Updated IAM policy for project [funky-monkey-283720].
bindings:
- members:
  - serviceAccount:167445686457@cloudbuild.gserviceaccount.com
  role: roles/cloudbuild.builds.builder
- members:
  - serviceAccount:service-167445686457@gcp-sa-cloudbuild.iam.gserviceaccount.com
  role: roles/cloudbuild.serviceAgent
- members:
  - serviceAccount:167445686457@cloudbuild.gserviceaccount.com
  role: roles/cloudfunctions.admin
- members:
  - serviceAccount:service-167445686457@gcf-admin-robot.iam.gserviceaccount.com
  role: roles/cloudfunctions.serviceAgent
- members:
  - serviceAccount:167445686457@cloudservices.gserviceaccount.com
  - serviceAccount:funky-monkey-283720@appspot.gserviceaccount.com
  - serviceAccount:service-167445686457@containerregistry.iam.gserviceaccount.com
  role: roles/editor
- members:
  - user:danieldsj@gmail.com
  role: roles/owner
etag: BwWqvZS6eyM=
version: 1
Updated IAM policy for serviceAccount [funky-monkey-283720@appspot.gserviceaccount.com].
bindings:
- members:
  - serviceAccount:167445686457@cloudbuild.gserviceaccount.com
  role: roles/iam.serviceAccountUser
etag: BwWqvZTTeuk=
version: 1
Creating a Google Cloud Source repository.
Created [funky].
WARNING: You may be billed for this repository. See https://cloud.google.com/source-repositories/docs/pricing for details.
Adding Google Cloud Source repository as remote to local Git repository.
Creating build trigger for when code is pushed to master.
Created [https://cloudbuild.googleapis.com/v1/projects/funky-monkey-283720/triggers/362a83fc-cc05-46fe-9f3b-f2932bea3b0c].
NAME     CREATE_TIME                STATUS
trigger  2020-07-18T21:01:51+00:00
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
  gcloud functions list --format='value(httpsTrigger.url)' --filter='entryPoint=funky'
```
