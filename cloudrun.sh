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

echo "Enabling Google Cloud Run API." >&2
[[ $(gcloud services list --format='value(config.name)' --filter='config.name=run.googleapis.com') ]] ||
  { gcloud services enable run.googleapis.com; }

echo "Adding permissions to default Cloud Build service account." >&2
# https://phpnews.io/feeditem/google-cloud-build-google-cloud-run-fixing-error-gcloud-run-deploy-permission-denied-the-caller-does-not-have-permission
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
  --role roles/run.admin

gcloud iam service-accounts add-iam-policy-binding \
  $PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --member="serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

echo "Creating a Google Cloud Source repository." >&2
gcloud source repos create $REPO_NAME

echo "Adding Google Cloud Source repository as remote to local Git repository." >&2
git remote add google https://source.developers.google.com/p/$PROJECT_ID/r/$REPO_NAME

echo "Generating sample index.html file." >&2
cat > index.html << EOF
<html><body>Hello, world!</body></html>
EOF

echo "Generating sample Dockerfile file." >&2
cat > Dockerfile << EOF
FROM nginx
COPY index.html /usr/share/nginx/html/
EOF

echo "Generating sample cloudbuild.yaml file." >&2
cat > cloudbuild.yaml << EOF
 steps:
 - name: 'gcr.io/cloud-builders/docker'
   id: 'Build image'
   args: ['build', '-t', 'gcr.io/$PROJECT_ID/${SERVICE_NAME}:\$COMMIT_SHA', '.']
 - name: 'gcr.io/cloud-builders/docker'
   id: 'Push image'
   args: ['push', 'gcr.io/$PROJECT_ID/${SERVICE_NAME}:\$COMMIT_SHA']
 - name: 'gcr.io/cloud-builders/gcloud'
   id: 'Deploy image'
   args:
   - 'run'
   - 'deploy'
   - '${SERVICE_NAME}'
   - '--image'
   - 'gcr.io/$PROJECT_ID/${SERVICE_NAME}:\$COMMIT_SHA'
   - '--region'
   - '${REGION}'
   - '--platform'
   - 'managed'
   - '--port'
   - '80'
   - '--cpu'
   - '1'
   - '--memory'
   - '128Mi'
   - '--cpu'
   - '200m'
   - '--max-instances'
   - '1'
   - '--allow-unauthenticated'
 images:
 - 'gcr.io/$PROJECT_ID/${SERVICE_NAME}:\$COMMIT_SHA'
EOF

echo "Creating build trigger for when code is pushed to master." >&2
[[ $(gcloud beta builds triggers list --filter="triggerTemplate.repoName=${REPO_NAME} AND triggerTemplate.branchName=master AND filename=cloudbuild.yaml" --format="value(id)") ]] ||
  { 
    gcloud beta builds triggers create cloud-source-repositories \
      --repo=$REPO_NAME \
      --branch-pattern="master" \
      --build-config="cloudbuild.yaml"
  };


echo "Operation complete. To deploy to Google Cloud Run, we recommend doing the following commands..."
echo "  git status"
echo "  git add ."
echo "  git commit -m 'First commmit.'"
echo "  git push google master"
echo " "
echo "To get the URL of your service, we recommend waiting a moment, and running the command..."
echo "  gcloud run services list --platform managed --format='value(status.address.url)' --filter='metadata.name=${SERVICE_NAME}'"
