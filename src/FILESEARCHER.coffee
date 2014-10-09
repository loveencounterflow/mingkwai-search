


############################################################################################################
# njs_fs                    = require 'fs'
# njs_path                  = require 'path'
njs_cp                    = require 'child_process'
njs_readline              = require 'readline'
#...........................................................................................................
TEXT                      = require 'coffeenode-text'
TYPES                     = require 'coffeenode-types'
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'XLTX'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
echo                      = TRM.echo.bind TRM
eventually                = process.nextTick


#-----------------------------------------------------------------------------------------------------------
### Test whether `agrep` is installed: ###
test = njs_cp.spawn 'agrep', [ '--version' ]
test.stderr.setEncoding 'utf-8'
test.stdout.setEncoding 'utf-8'
#...........................................................................................................
test.on 'error', ( error ) ->
  console.log 'error', rpr error
  if error[ 'code' ] is 'ENOENT'
    log()
    alert "it looks like `agrep` is not installed"
    help "please visit https://github.com/Wikinaut/agrep to fix this"
  throw error

#-----------------------------------------------------------------------------------------------------------
@_search = ( route, pattern, handler ) ->
  Z             = null
  pattern       = pattern.replace /"/g, '\\"'
  # pattern       = '"'.concat pattern, '"'
  #.........................................................................................................
  command       = 'agrep'
  parameters    = [
    # '--color'
    # '--with-filename'
    '--line-number'
    '--show-position'
    pattern
    route ]
  #.........................................................................................................
  log TRM.pink command.concat ' ', parameters.join ' '
  options           = {}
  child_process     = njs_cp.spawn command, parameters, options
  # result_collector  = []
  error_collector   = []
  child_process.stderr.setEncoding 'utf-8'
  child_process.stdout.setEncoding 'utf-8'
  line_reader       = njs_readline.createInterface child_process.stdout, child_process.stdin
  #.........................................................................................................
  child_process.stderr.on 'data', ( data ) =>
    error_collector.push data
  #.........................................................................................................
  line_reader.on 'line', ( line ) ->
    handler null, line
  #.........................................................................................................
  child_process.stdout.on 'end', =>
    ### Filter errors for non-empty lines that do not show the standard 'skipping rest of file'
    notification: ###
    errors = TEXT.lines_of error_collector.join ''
    errors = errors.filter ( line ) ->
      return line.length > 0 and not ( line.match /^ERR: Too many matches in / )?
    if errors.length isnt 0
      return new Error handler errors.join '\n'
    #.......................................................................................................
    handler null, null
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@search = ( route, pattern, handler ) ->
  #.........................................................................................................
  if ( not pattern? ) or pattern.length is 0
    return handler null, null
  #.........................................................................................................
  unless TYPES.isa_text pattern
    return handler new Error "expected a text for pattern, got a #{TYPES.type_of pattern}"
  #.........................................................................................................
  result_count    = 0
  result_matcher  = /// ^ ( [0-9]+ ) : ( [0-9]+ ) - ( [0-9]+ ) : ( .+ )   $ ///
  #.........................................................................................................
  @_search route, pattern, ( error, line ) =>
    throw error if error?
    return handler null, null if line is null
    # return unless line.length > 0
    #.......................................................................................................
    # log TRM.yellow '©23a           ', rpr line
    match   = line.match result_matcher
    # #.......................................................................................................
    # unless match?
    #   log TRM.red "irregular line: #{rpr line}"
    #   return
    #.......................................................................................................
    if match?
      [ ignored
        line_nr_txt
        start_chr_nr_txt
        stop_chr_nr_txt
        find            ] = match
    else
      line_nr_txt       = '0'
      start_chr_nr_txt  = '0'
      stop_chr_nr_txt   = '0'
      find              = ''
    #.......................................................................................................
    line_nr             = parseInt      line_nr_txt, 10
    start_chr_idx       = parseInt start_chr_nr_txt, 10
    stop_chr_idx        = parseInt  stop_chr_nr_txt, 10
    result_count       += 1
    ### TAINT `agrep` would appear to have issues with UTF-8 and miscount bytes with some inputs. We handle
    this situation by foregoing match hiliting for the time being. ###
    # info '©28u', line_nr, start_chr_idx, stop_chr_idx, ( TRM.grey find ), TRM.gold rpr find[ start_chr_idx ... stop_chr_idx ]
    # head                = find[               ... start_chr_idx ]
    # body                = find[ start_chr_idx ...  stop_chr_idx ]
    # tail                = find[  stop_chr_idx ...               ]
    # handler null, [ route, line_nr, [ head, body, tail, ], ]
    handler null, [ route, line_nr, [ find, ], ]
  #.........................................................................................................
  return null

############################################################################################################
### show demo ###
if is_toplevel = process.argv[ 1 ] is __filename
  route   = '/Users/flow/JIZURA/flow/datasources/shape/shape-breakdown-formula.txt'
  route   = '/Users/flow/JIZURA/flow/datasources/shape/shape-strokeorder-zhaziwubifa.txt'
  # pattern = '12345'
  pattern = 'jzr-fig'
  @search route, pattern, ( error, result ) ->
    throw error if error?
    if result is null
      log TRM.green 'OK'
      return null
    [ route, line_nr, finds, ] = result
    log ( TRM.grey route ), ( TRM.yellow line_nr ), ( TRM.lime finds )





