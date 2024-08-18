# Overview

Extract and load.

# Initial setup

## Start setting up the GitHub repository

1. In GitHub, click "Use this template", then "Create a new repository".
1. Enter a repository name, such as syncsurveycto-xyz, where xyz is the name of the SurveyCTO server to be synced, and click "Create repository".
1. Clone the new repo to a directory on your machine of choice.
1. Rename syncsurveycto-rsurveycto.Rproj to match the new repo's name.
1. In the repo's main directory, create a folder called secrets.
1. Start an R session in the new repo's main directory. You should see a message that a project was loaded by [renv](https://rstudio.github.io/renv/index.html).
1. In R, run `renv::upgrade()` to ensure the repo is using the latest version of renv.
1. In R, run `renv::restore()` to restore the local project library.

## Set up SurveyCTO

1. In the secrets folder, create a file called scto_auth.txt containing the server name on the first line, username on the second, and password on the third. This username must have permission to download data and "allow server API access" must be enabled.

## Set up the data warehouse

### Google BigQuery

1. If you haven't already, create a Google Cloud project named something like xyz-raw, where xyz is the name of your organization.
1. Select the project and enable the BigQuery API.
1. Create a service account named syncsurveycto-user.
1. Create a JSON key for the service account, and download the JSON file to the secrets folder.
1. For the project, give the service account (whose email address will be something like syncsurveycto-user@iam.xyz-raw.gserviceaccount.com) the role BigQuery User.
1. Create two BigQuery datasets named surveycto and surveycto_dev.
1. For each of the two datasets, click Share, then Manage Permissions, then Add Principal, then add the information below (changing xyz-raw as appropriate), and click Save.
    - Add principals: syncsurveycto-user@iam.xyz-raw.gserviceaccount.com
    - Assign roles: BigQuery Data Editor
1. Update the params/warehouse.yaml file, changing xyz-raw as appropriate:
    - auth_file: Name of the JSON file for the service account
    - project (for prod and dev environments): xyz-raw

### Postgres

1. Seriously consider not using Postgres as a data warehouse, and instead using BigQuery.
2. That is all for now.

## Finish setting up the GitHub repository

1. In the new GitHub repo, click Settings, then "Secrets and variables", then Actions.
1. Click "New repository secret", enter the information below, then click "Add secret".
    - Name: SCTO_AUTH
    - Secret: Content of scto_auth.txt, *with no trailing line break*.
1. Once again, click "New repository secret", enter the information below, then click "Add secret".
    - Name: WH_AUTH
    - Secret: Content of the auth_file specified in params/warehouse.yaml.
1. In the git repo on your local machine, make a git commit and push the changes to GitHub.
1. In the GitHub repo, go to Actions and ensure that a GitHub Actions run has started and that it completes without error.
1. Once the run completes, click on sync_surveycto to see the job details, and ensure that the final line of the "Run script" step says "No ids to sync."

# Sync modes

| Sync mode   | Airbyte equivalent         | Supported for forms | Supported for datasets |
|-------------|----------------------------|---------------------|------------------------|
| overwrite   | [Full Refresh Overwrite](https://docs.airbyte.com/using-airbyte/core-concepts/sync-modes/full-refresh-overwrite)     | ✓                   | ✓*                     |
| append      | [Full Refresh Append](https://docs.airbyte.com/using-airbyte/core-concepts/sync-modes/full-refresh-append)        | ✓                   | ✓                      |
| incremental | [Incremental Append](https://docs.airbyte.com/using-airbyte/core-concepts/sync-modes/incremental-append)         | ✓                   | -                      |
| deduped     | [Incremental Append Deduped](https://docs.airbyte.com/using-airbyte/core-concepts/sync-modes/incremental-append-deduped) | ✓*                  | -                      |

\* Recommended

# Add a form or dataset to the pipeline

1. On your local machine, ensure you are not on the main branch.
1. Update params/surveycto.yaml by adding two lines to the streams list of the **dev** section, as indicated below. Take care with indentation.
    ```
    - id: best_id_ever
      sync_mode: chosen_sync_mode
    ```
1. In the terminal, run `Rscript code/main.R` and ensure that the syncs succeed.
1. Go to the part of your warehouse specified in the **dev** environment of the params/warehouse.yaml file and ensure that the columns, number of rows, and content of the new table(s) look(s) right.
1. Carefully copy the two lines for id and sync_mode and paste them into the streams list of the **prod** section. Remember, [this is Sparta](https://youtu.be/cAacE5ukzrs?feature=shared&t=170).
1. Make a git commit and push the changes to GitHub.
1. On GitHub, create a sensibly named pull request and add someone as a reviewer.
1. Ensure that the syncs initiated by the pull request and run on GitHub Actions succeed.
1. Ensure that the table(s) in **dev** still look(s) right.
1. Wait for the reviewer to approve and merge the pull request.
1. Once the pull request is merged, ensure that the syncs run on GitHub Actions succeed.
1. Ensure that the table(s) in **prod** look(s) right.

# Remove a form or dataset from the pipeline

1. On your local machine, ensure you are not on the main branch.
1. Update params/surveycto.yaml by deleting or commenting out the two lines for id and sync_mode from the streams lists of the **dev** and the **prod** sections.
1. In the terminal, run `Rscript code/main.R` and ensure that the syncs succeed.
1. Make a git commit and push the changes to GitHub.
1. On GitHub, create a sensibly named pull request and add someone as a reviewer.
1. Ensure that the syncs initiated by the pull request and run on GitHub Actions succeed.
1. Wait for the reviewer to approve and merge the pull request.
1. Once the pull request is merged, ensure that the syncs run on GitHub Actions succeed.
1. The table(s) for the form or dataset will remain in BigQuery, but will not be updated.

# Update packages used by the pipeline

1. On your local machine, ensure you are not on the main branch.
1. In R, run `renv::update()` to update all packages or `renv::update('agency-fund/syncsurveycto')` to update syncsurveycto.
1. In R, run `renv::snapshot()`.
1. If the renv.lock file has changed, continue with the steps below. If not, stop here.
1. In the terminal, run `Rscript code/main.R` and ensure that the syncs succeed and that the tables in **dev** still look right.
1. Make a git commit and push the changes to GitHub.
1. On GitHub, create a sensibly named pull request and add someone as a reviewer.
1. Ensure that the syncs initiated by the pull request and run on GitHub Actions succeed.
1. Ensure that the tables in **dev** still look right.
1. Wait for the reviewer to approve and merge the pull request.
1. Once the pull request is merged, ensure that the syncs run on GitHub Actions succeed.
1. Ensure that the tables in **prod** still look right.

# Update the schedule on which the pipeline runs

1. On your local machine, ensure you are not on the main branch.
1. In the .github/workflows/sync_surveycto.yaml file, edit the line that starts with "- cron:". See details [here](https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows#schedule).
1. Make a git commit and push changes to GitHub.
1. On GitHub, create a sensibly named pull request and add someone as a reviewer.
1. Ensure that the syncs initiated by the pull request and run on GitHub Actions succeed.
1. Wait for the reviewer to approve and merge the pull request.
1. Once the pull request is merged, ensure that the syncs run on GitHub Actions succeed and that they run on the intended schedule.
