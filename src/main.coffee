


require 'coffee-script/register'




############################################################################################################
# njs_fs                    = require 'fs'
njs_path                  = require 'path'
njs_os                    = require 'os'
njs_http                  = require 'http'
njs_url                   = require 'url'
#...........................................................................................................
TYPES                     = require 'coffeenode-types'
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = '明快main'
log                       = TRM.get_logger 'plain', badge
info                      = TRM.get_logger 'info',  badge
alert                     = TRM.get_logger 'alert', badge
debug                     = TRM.get_logger 'debug', badge
warn                      = TRM.get_logger 'warn',  badge
help                      = TRM.get_logger 'help',  badge
echo                      = TRM.echo.bind TRM
templates                 = require './templates'
O                         = require '../options'
#...........................................................................................................
# MOJIKURA                  = require 'coffeenode-mojikura'
FILESEARCHER              = require './FILESEARCHER'
DATASOURCES               = require 'jizura-datasources'
DSREGISTRY                = DATASOURCES.REGISTRY
# db                        = MOJIKURA.new_db()
#...........................................................................................................
### https://github.com/dominictarr/my-local-ip ###
get_my_ip                 = require 'my-local-ip'
#...........................................................................................................
### TAINT: this stuff should go into options ###
os_name                   = njs_os.platform()
#...........................................................................................................
### https://github.com/cloudhead/node-static ###
STATIC                    = require 'node-static'
static_route              = './public'
log_static_requests       = yes
file_server               = new STATIC.Server static_route
server                    = njs_http.createServer()
#...........................................................................................................
server_info = server[ 'info' ] =
  'os-name':        os_name
  'address':        null
  'port':           null
  'host':           null
  'routes':         []
  'started':        null
  'request-count':  0
#...........................................................................................................
if os_name is 'darwin'
  server_info[ 'port' ]     = 80
  server_info[ 'host' ]     = get_my_ip()
#...........................................................................................................
else
  server_info[ 'port' ]     = 8080
  server_info[ 'host' ]     = '142.4.222.238'
#...........................................................................................................
server_info[ 'address' ]  = "http://#{server_info[ 'host' ]}:#{server_info[ 'port' ]}"
#...........................................................................................................
### https://github.com/caolan/async ###
ASYNC                     = require 'async'
async_limit               = 5
#...........................................................................................................
### https://github.com/aaronblohowiak/routes.js ###
static_router             = ( require 'routes' )()
COOKIE                    = require 'cookie'
#...........................................................................................................
@_cut_here_mark           = '✂cut-here✂'
@_cut_here_matcher        = /// <!-- #{@_cut_here_mark} --> ///
#...........................................................................................................
LIMIT                     = require 'coffeenode-limit'
limit_registry            = LIMIT.new_registry()
LIMIT.new_user limit_registry, 'localhost',           'premium'
LIMIT.new_user limit_registry, '127.0.0.1',           'premium'
LIMIT.new_user limit_registry, server_info[ 'host' ], 'premium'
# LIMIT.new_user limit_registry, server_info[ 'host' ], 'default'
# LIMIT.new_user limit_registry, server_info[ 'host' ], 'spam'

#-----------------------------------------------------------------------------------------------------------
handle_static = ( request, response, routing ) ->
  # log TRM.pink routing
  filename          = routing[ 'splats' ][ 0 ]
  #.........................................................................................................
  if log_static_requests
    fileroute = njs_path.join __dirname, static_route, filename
    # log TRM.grey '©34e', "static: #{request[ 'url' ]} ⇒ #{fileroute}"
  #.........................................................................................................
  # static_fileroute  = '/public/'.concat filename
  static_fileroute  = filename
  request[ 'url' ]  = static_fileroute
  file_server.serve request, response

#-----------------------------------------------------------------------------------------------------------
handle_favicon = ( request, response, routing ) ->
  # request[ 'url' ] = 'favicon.ico'
  log TRM.pink 'favicon:', request[ 'url' ]
  # request[ 'url' ]  = 'public/favicon.ico'
  request[ 'url' ]  = 'favicon.ico'
  file_server.serve request, response

#-----------------------------------------------------------------------------------------------------------
static_router.addRoute  '/public/*',      handle_static
static_router.addRoute  '/favicon.ico',   handle_favicon
static_router.addRoute  '/favicon.ico*',  handle_favicon

#-----------------------------------------------------------------------------------------------------------
@write_http_head = ( response, status_code, cookie ) ->
  #.........................................................................................................
  headers =
    'Content-Type':         'text/html'
    'Connection':           'keep-alive'
    'Transfer-Encoding':    'chunked'
  #.........................................................................................................
  headers[ 'Cookie' ] = ( COOKIE.serialize name, value for name, value of cookie ) if cookie?
  #.........................................................................................................
  response.writeHead status_code, headers
  return null

#-----------------------------------------------------------------------------------------------------------
@distribute = ( request, response ) ->
  server[ 'info' ][ 'request-count' ]  += 1
  #.........................................................................................................
  url = request[ 'url' ]
  #.........................................................................................................
  # Serve static files:
  return routing[ 'fn' ] request, response, routing if ( routing = static_router.match  url )?
  #.........................................................................................................
  ### Limiting Access based on IP ###
  uid = request.connection.remoteAddress
  LIMIT.permesso limit_registry, uid, ( error, ok, eta ) =>
    throw error if error? # (should never happen)
    #.......................................................................................................
    return @refuse  request, response, uid, url, eta unless ok
    return @respond request, response, uid, url
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@refuse = ( request, response, uid, url, ms_to_wait ) ->
  @write_http_head response, 429
  response.write templates.refuse
    'reason':         "TOO MANY REQUESTS."
    'ms-to-wait':     ms_to_wait
  response.end()

#-----------------------------------------------------------------------------------------------------------
@respond = ( request, response, uid, url ) ->
  t0                = 1 * new Date()
  rqid              = "RQ##{server[ 'info' ][ 'request-count' ]}"
  #.........................................................................................................
  parsed_url        = njs_url.parse url, true
  route             = parsed_url[ 'pathname' ]
  last_query        = parsed_url[ 'query' ]
  q                 = last_query[ 'q' ] ? null
  Δ                 = response.write.bind response
  all_ds_infos      = DSREGISTRY[ 'ds-infos' ]
  dsids             = {}
  gids              = {}
  ds_infos          = []
  do_search_db      = last_query[ 'db' ] is 'db'
  #.........................................................................................................
  if request[ 'headers' ][ 'cookie' ]? then cookie = COOKIE.parse request[ 'headers' ][ 'cookie' ]
  else                                      cookie = {}
  #.........................................................................................................
  help '©34x', rqid, 'cookie:', cookie
  help '©34x', rqid, 'url:   ', url
  help '©34x', rqid, 'route: ', route
  tainted_languagecode = cookie[ 'languagecode' ] ? 'en_US'
  # #.........................................................................................................
  # ### TAINT kludge ###
  # if route is '/missing-guides'
  #   warn "not implemented: #{rpr route}"
  # else
  #.........................................................................................................
  do ( dsid = null, ds_info = null, ds = null ) =>
    ds = last_query[ 'ds' ] ? []
    ds = [ ds, ] unless TYPES.isa_list ds
    for dsid in ds
      ds_info = all_ds_infos[ dsid ]
      # log TRM.yellow '©32s', dsid, ds_info
      continue unless ds_info?
      dsids[ dsid ] = 1
      ds_infos.push ds_info
  #.........................................................................................................
  ### TAINT code duplication ###
  do ( gid = null, ds_info = null, dg = null ) =>
    dg = last_query[ 'dg' ] ? []
    dg = [ dg, ] unless TYPES.isa_list dg
    for gid in dg
      continue unless DSREGISTRY[ 'groupname-by-gid' ][ gid ]?
      gids[ gid ] = 1
      # ds_infos.push ds_info
  #.........................................................................................................
  log TRM.green '©23k', rqid, last_query
  #.........................................................................................................
  html = templates.main
    'rqid':                   rqid
    'title':                  "明快搜字機 MingKwai Type Tool"
    'headline':               "明快搜字機<br>MingKwai Type Tool"
    'results':                []
    'result-type':            'ag'
    'dt':                     0
    'last-query':             last_query
    'request-count':          server[ 'info' ][ 'request-count' ]
    'db':                     do_search_db
    'dsids':                  dsids
    'gids':                   gids
    'cut-here-mark':          @_cut_here_mark
    'languagecode':           tainted_languagecode
  #.........................................................................................................
  [ html_front
    html_rear ] = html.split @_cut_here_matcher
  #.........................................................................................................
  throw new Error "unable to split HTML: no cut mark found" unless html_rear?
  #.........................................................................................................
  result_count  = 0
  buffer        = []
  #.........................................................................................................
  send_buffer = =>
    unless ( R = buffer.length ) is 0
      Δ buffer.join '\n'
      buffer.length = 0
      Δ templates.update_result_count
        result_nr:      result_count
        result_count:   result_count
    return R
  #.........................................................................................................
  finalize_response = =>
    send_buffer()
    Δ html_rear
    response.end()
    warn '©23k', rqid, 'finished'
  #.........................................................................................................
  @write_http_head response, 200, cookie
  Δ html_front
  #.........................................................................................................
  last_idx = ds_infos.length - 1
  #.........................................................................................................
  if last_idx < 0
    warn '©34w', rqid, "no data sources specified"
    # log ds_infos
    return finalize_response()
  #.........................................................................................................
  else
    log TRM.green '©34w', rqid, "searching in #{ds_infos.length} sources"
    ###
    #.......................................................................................................
    search_db = ( async_handler ) =>
      id = "glyph:#{q}"
      debug '©27t', id
      #.....................................................................................................
      MOJIKURA.get db, id, null, ( error, glyph_entry ) =>
        return async_handler error if error?
        # debug '©23w', JSON.stringify glyph_entry
        #...................................................................................................
        if glyph_entry?
          result_count += 1
          #.................................................................................................
          buffer.push templates.result_row
            'rqid':                   rqid
            'result':                 [ glyph_entry, ]
            'result-type':            'db'
            'dsid':                   'db'
            'result-nr':              result_count
            'result-count':           result_count
            'languagecode':           tainted_languagecode
          # #...............................................................................................
          # send_buffer() if buffer.length >= 2
        #...................................................................................................
        async_handler null, null
    ###
    #.......................................................................................................
    search_ds_file = ( ds_info, async_handler ) =>
      dsid      = ds_info[ 'id' ]
      ds_route  = ds_info[ 'route' ]
      ds_name   = ds_info[ 'name'  ]
      #.....................................................................................................
      # debug '©88z', rpr q
      FILESEARCHER.search ds_route, q, ( error, result ) =>
        debug 'XXXX' + error[ 'message' ] if error?
        #...................................................................................................
        return async_handler null, null if result is null
        # log TRM.blue data_route, result.join ' '
        #...................................................................................................
        result_count += 1
        #...................................................................................................
        buffer.push templates.result_row
          'rqid':                   rqid
          'result':                 result
          'result-type':            'ds'
          'dsid':                   dsid
          'result-nr':              result_count
          'result-count':           result_count
          'languagecode':           tainted_languagecode
        #...................................................................................................
        send_buffer() if buffer.length >= 2
    #.......................................................................................................
    tasks = []
    tasks.push ( handler ) =>
      ASYNC.eachLimit ds_infos, async_limit, search_ds_file, ( error ) =>
        handler error, null
    #.......................................................................................................
    if do_search_db
      warn "searching in MojiKuraDB currently not possible"
      # debug "searching in MojiKuraDB"
      # tasks.push ( handler ) =>
      #   search_db ( error ) =>
      #     handler error, null
    #.......................................................................................................
    ASYNC.parallel tasks, finalize_response
  #.........................................................................................................
  return null


#===========================================================================================================
# EVENT HANDLING
#-----------------------------------------------------------------------------------------------------------
server.on 'request', @distribute.bind @

#-----------------------------------------------------------------------------------------------------------
server.on 'close', =>
  warn "server #{server_address} closed"

#-----------------------------------------------------------------------------------------------------------
server.on 'error', ( error ) =>
  alert "when trying to start serving on #{server_info[ 'address' ]}, an error was encountered:"
  alert rpr error[ 'message' ]
  if error[ 'message' ] is "listen EACCES" and server_info[ 'port' ] < 1024
    help "since the configured port is below 1024, you should probably"
    help "try and start the server using `sudo`"
  throw error

#-----------------------------------------------------------------------------------------------------------
process.on 'uncaughtException', ( error ) ->
  alert 'uncaughtException'
  throw error


############################################################################################################
# MAKE IT SO
#-----------------------------------------------------------------------------------------------------------
@start = ( handler ) ->
  server_info[ 'routes' ].push route for route of static_router.routeMap
  server.listen server_info[ 'port' ], server_info[ 'host' ], ( error, P... ) =>
    server[ 'info' ][ 'started' ] = new Date()
    handler null, server_info if handler?


#   # curl -H "X-Forwarded-For: 1.2.3.4" http://192.168.178.25









