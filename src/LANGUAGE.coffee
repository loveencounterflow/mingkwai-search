

############################################################################################################
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
log                       = TRM.log.bind TRM
echo                      = TRM.echo.bind TRM
CHR                       = require 'coffeenode-chr'
#...........................................................................................................
@translations             = require './translations'

#-----------------------------------------------------------------------------------------------------------
@get_languagecode_and_translator_with_fallback = ( languagecode ) ->
  try
    translator    = @get_translator languagecode
  catch error
    throw error unless ( error[ 'message' ].match /^unknown locale specifier: / )?
    languagecode  = 'en_US'
    translator    = @get_translator languagecode
  return [ languagecode, translator, ]

#-----------------------------------------------------------------------------------------------------------
@get_translator = ( languagecode ) ->
  fallback_languagecode = 'en_US'
  translations          = @translations[          languagecode ]
  fallback_translations = @translations[ fallback_languagecode ]
  is_valid              = ( translation ) -> return translation? and translation.length > 0
  #.........................................................................................................
  throw Error "unknown locale specifier: #{rpr languagecode}" unless translations?
  #.........................................................................................................
  # do ( translations ) =>
  return ( text ) =>
    R =          translations[ text ]
    R = fallback_translations[ text ] if ( languagecode isnt fallback_languagecode ) and ( not is_valid R )
    R = text                          if not is_valid R
    return R

############################################################################################################
# module.exports = @get_translator.bind @
