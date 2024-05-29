# ubi-trino

Docker Image build from RHEL UBI base image

# Workflow

## Basic workflow

1. Branch from `main`
2. Make changes
4. Commit and Push
5. Create PR merging into `main`
6. Get reviewed and approved

## Build new version of Trino

1. Checkout `main` and pull
2. Execute `check_upstream.sh` If it reports _Up to date with trinodb/trino_ then stop.
3. If it reports a new trino version number, then branch from `main` for that new version.
4. Update `Dockerfile` : `ARG TRINO_VERSION` setting it to the version reported.
7. Run a test build by executing `pr_check.sh`
8. If successful, then commit changes and push branch.
9. Create a PR, this should execute a PR check script.
10. If successful, get approval and merge.

* Note: If the UBI image version is updated in the Dockerfile you must also update the `check-image.yml` workflow.

# Utility Scripts

* `check_upstream.sh` : Check the current version of trino set in the Dockerfile against release tags from the `trinodb/trino` repo.
* `get_latest_repo_release_tag.sh` : Get the latest release tag from the `trinodb/trino repo`.
* `docker-build-dev.sh` : Executes a local test build of the docker image.
* `get_image_tag.sh` : Return the image tag made from the trino version and commit hash.

# Integration Scripts

* `pr_check.sh` : PR check script (You should not need to modify this)
* `build_deploy.sh` : Build and deploy to Red Hat cloudservices quay org. (You should not need to modify this script)

