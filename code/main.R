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

send_slack_message = \(txt, channel, token = NULL) {
  if (is.null(token)) token = Sys.getenv('SLACK_TOKEN')
  httr::POST(
    url = 'https://slack.com/api/chat.postMessage',
    httr::add_headers(Authorization = paste('Bearer', token)),
    body = list(channel = channel, text = txt))
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
  send_slack_message(txt, channel = slack_params$channel_id)
  stop(e)
})
