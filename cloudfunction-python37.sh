#!/bin/bash

echo "Checking arguments." >&2
[[ $# -eq 1 ]] || 
  { echo "Command takes 1 arguments.  Example usage: $0 <FRIENDLY_NAME>"; exit 1; }

echo "Checking for presence Cloud SDK." >&2
[[ $(which gcloud) ]] || 
  { echo "Cloud SDK not configued, exiting."; exit 1; }

echo "Checking if user is authenticated." >&2
[[ $(gcloud auth list --filter 'status=ACTIVE' --format 'value(account)') ]] || 
  { echo "Not logged in. Please log in using 'gcloud auth login' command."; exit 1; }

echo "Checking if project is set." >&2
[[ $(gcloud config get-value project) ]] || 
  { echo "No project configured. Set the project using the 'gcloud config set project <PROJECT>' command."; exit 1; }

echo "Checking if present working directory is a Git repository." >&2
[[ $(git rev-parse --is-inside-work-tree) ]]  ||
  { echo "Currently not in a initialized git repository. Initialize git repository first."; exit 1;}

REPO_NAME="${1}"
SERVICE_NAME="${1}"
REGION="us-central1"
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects list --filter="project_id=${PROJECT_ID}" --format="value(project_number)")

echo "Enabling Google Cloud Build API." >&2
[[ $(gcloud services list --format='value(config.name)' --filter='config.name=cloudbuild.googleapis.com') ]] ||
  { gcloud services enable cloudbuild.googleapis.com; }

echo "Enabling Google Cloud Source Repository API" >&2
[[ $(gcloud services list --format='value(config.name)' --filter='config.name=sourcerepo.googleapis.com') ]] ||
  { gcloud services enable sourcerepo.googleapis.com; }

echo "Enabling Google Cloud Functions API." >&2
[[ $(gcloud services list --format='value(config.name)' --filter='config.name=cloudfunctions.googleapis.com') ]] ||
  { gcloud services enable cloudfunctions.googleapis.com; }

echo "Adding permissions to default Cloud Build service account." >&2
# https://stackoverflow.com/questions/58544241/correct-permissions-for-google-cloud-build-to-deploy-a-cloudfunction-in-a-separa
# https://cloud.google.com/iam/docs/understanding-roles#cloud-functions-roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
  --role roles/cloudfunctions.admin

gcloud iam service-accounts add-iam-policy-binding \
  $PROJECT_ID@appspot.gserviceaccount.com \
  --member="serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

echo "Creating a Google Cloud Source repository." >&2
gcloud source repos create $REPO_NAME

echo "Adding Google Cloud Source repository as remote to local Git repository." >&2
git remote add google https://source.developers.google.com/p/$PROJECT_ID/r/$REPO_NAME

echo "Creating build trigger for when code is pushed to master." >&2
[[ $(gcloud beta builds triggers list --filter="triggerTemplate.repoName=${REPO_NAME} AND triggerTemplate.branchName=master AND filename=cloudbuild.yaml" --format="value(id)") ]] ||
  { 
    gcloud beta builds triggers create cloud-source-repositories \
      --repo=$REPO_NAME \
      --branch-pattern="master" \
      --build-config="cloudbuild.yaml"
  };

echo "Generating sample main.py file." >&2
cat > main.py << EOF
def ${SERVICE_NAME}(request):
  return "Hello World!"
EOF

echo "Generating sample test_main.py file." >&2
cat > test_main.py << EOF
import unittest
import main

class Test(unittest.TestCase):
    def test_${SERVICE_NAME}(self):
        self.assertEqual(main.${SERVICE_NAME}(None), "Hello World!")
EOF

echo "Generating sample requirements.txt file." >&2
cat > requirements.txt << EOF
coverage==5.1
EOF

echo "Generating sample cloudbuild.yaml file." >&2
cat > cloudbuild.yaml << EOF
steps:
  - name: 'python:3.7-slim'
    id: Test
    entrypoint: /bin/sh
    args:
    - -c
    - 'pip install -r requirements.txt && coverage run -m unittest discover && coverage report -m --fail-under=95'
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk:slim'
    id: Deploy
    entrypoint: 'gcloud'
    args:
    - 'functions'
    - 'deploy'
    - '${SERVICE_NAME}'
    - '--region=${REGION}'
    - '--service-account=${PROJECT_ID}@appspot.gserviceaccount.com'
    - '--max-instances=1'
    - '--allow-unauthenticated'
    - '--runtime=python37'
    - '--trigger-http'
EOF

echo "Operation complete. To deploy to Google Cloud Functions, we recommend doing the following commands..."
echo "  git status"
echo "  git add ."
echo "  git commit -m 'First commmit.'"
echo "  git push google master"
echo " "
echo "To get the URL of your service, we recommend waiting a moment, and running the command..."
echo "  gcloud functions list --format='value(httpsTrigger.url)' --filter='entryPoint=${SERVICE_NAME}'"
