#!/usr/bin/env bash

# Workspace directory
WORKSPACE_DIR="${HOME}/workspace"
mkdir -p "$WORKSPACE_DIR"

# Get list of organizations you have access to
ORGS=$(gh api user/orgs --jq '.[].login')

# Loop through each organization
for ORG in $ORGS; do
  # Create a directory for the organization
  ORG_DIR="${WORKSPACE_DIR}/${ORG}"
  mkdir -p "$ORG_DIR"

  echo "Cloning repositories for organization: $ORG"

  # Get list of repositories in the organization
  gh repo list "$ORG" --limit 1000 --json name --jq '.[].name' | while read -r REPO; do
    REPO_DIR="${ORG_DIR}/${REPO}"

    # Clone the repository if it doesn't already exist
    if [ ! -d "$REPO_DIR" ]; then
      echo "Cloning $ORG/$REPO into $REPO_DIR"
      gh repo clone "$ORG/$REPO" "$REPO_DIR"
    else
      echo "Repository $ORG/$REPO already exists in $REPO_DIR"
    fi
  done
done

echo "All repositories have been cloned into the workspace: $WORKSPACE_DIR"