library('syncsurveycto')

get_slack_message_text = \(e) {
  txt = glue::glue(
    ':warning: Sync for SurveyCTO failed with the following error:',
    '\n\n`{trimws(as.character(e))}`')
  run_url = Sys.getenv('GITHUB_RUN_URL')
  if (run_url != '') {
    txt = txt + glue::glue(
      '\n\n\nPlease see the GitHub Actions <{run_url}|workflow run log>.')
  }
  txt
}

tryCatch({
  scto_params = get_params(file.path('params', 'surveycto.yaml'))
  wh_params = get_params(file.path('params', 'warehouse.yaml'))

  foreach::registerDoSEQ()
  sync_surveycto(scto_params, wh_params)

}, error = \(e) {
  if (wh_params$environment != 'prod') stop(e)
  txt = get_slack_message_text(e)
  slack_params = get_params(file.path('params', 'slack.yaml'))
  slackr::slackr_msg(txt, channel = slack_params$channel_id)
  stop(e)
})
