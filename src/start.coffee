
require 'coffee-script/register'


############################################################################################################
njs_url                   = require 'url'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
log_                      = TRM.log.bind TRM
badge                     = TRM.darkgrey '明快start'
log                       = TRM.get_logger 'info', badge
alert                     = TRM.get_logger 'alert', badge
warn                      = TRM.get_logger 'warn', badge
help                      = TRM.get_logger 'help', badge
echo                      = TRM.echo.bind TRM
#...........................................................................................................
MINGKWAI                  = require '..'
O                         = require '../options'
#...........................................................................................................
### https://github.com/jandre/node-userid ###
USERID                    = require 'userid'


############################################################################################################
MINGKWAI.start ( error, info ) ->
  ### TAINT hardcoded username == bad ###
  try
    process.setgid O[ 'run-as-group' ]
    process.setuid O[ 'run-as-user'  ]
  catch error
    log()
    alert "when trying to set process GID/UID, an error was encountered:"
    alert rpr error[ 'message' ]
    options_route = require.resolve '../options'
    if /setgid group id does not exist/.test error[ 'message' ]
      log()
      help "the given group ID #{rpr O[ 'run-as-group' ]} is invalid"
      help "you should review the settings in file"
      help TRM.route options_route
    else if /setuid user id does not exist/.test error[ 'message' ]
      log()
      help "the given user ID #{rpr O[ 'run-as-user' ]} is invalid"
      help "you should review the settings in file"
      help TRM.route options_route
    throw error
  # log process.env
  uid       = process.getuid()
  gid       = process.getgid()
  username  = USERID.username   uid
  groupname = USERID.groupname  gid
  #.........................................................................................................
  log()
  log TRM.grey "——————————————————————————————————————————————————————"
  log TRM.cyan "眀快搜字機 MingKwai Type Tool"
  log TRM.cyan "A web front end for the MojiKura database"
  log TRM.grey "——————————————————————————————————————————————————————"
  log()
  log TRM.grey "操作系統名稱/OS:  #{info[ 'os-name' ]}"
  log TRM.grey "用戶標識符/User:  #{uid} (#{username})"
  log TRM.grey "小組標識符/Group: #{gid} (#{groupname})"
  log()
  log TRM.gold '靜態路徑/static routes:'
  for route in info[ 'routes' ]
    url =
      protocol:     'http'
      hostname:     info[ 'host' ]
      port:         info[ 'port' ]
      pathname:     route
    log '  '.concat TRM.gold njs_url.format url
  log()
  log TRM.green "server with PID #{process[ 'pid' ]} listening on #{info[ 'address' ]}"
  log()

