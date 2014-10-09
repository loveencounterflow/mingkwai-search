


# http://www.zdic.net/sousuo?q=...
# http://wadoku.de/search?query=...
# http://lingweb.eva.mpg.de/kanji/index.html?kanji=...


############################################################################################################
TRM                       = require 'coffeenode-trm'
TYPES                     = require 'coffeenode-types'
rpr                       = TRM.rpr.bind TRM
log                       = TRM.log.bind TRM
echo                      = TRM.echo.bind TRM
CHR                       = require 'coffeenode-chr'
LANGUAGE                  = require './LANGUAGE'
DATASOURCES               = require 'jizura-datasources'
DSREGISTRY                = DATASOURCES.REGISTRY
ids_translations          = require './ids-translations'
#...........................................................................................................
### http://momentjs.com ###
MOMENT                    = require 'moment'
#...........................................................................................................
### https://github.com/goodeggs/teacup ###
teacup                    = require 'teacup'

#===========================================================================================================
# TEACUP NAMESPACE ACQUISITION
#-----------------------------------------------------------------------------------------------------------
for name_ of teacup
  eval "#{name_.toUpperCase()} = teacup[ #{rpr name_} ]"

#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
@_markup_text = ( text ) ->
  R     = []
  #.........................................................................................................
  markup_options =
    input:          'xncr'
    output:         'html'
  #.........................................................................................................
  cells = text.split /\t/g
  #.......................................................................................................
  for cell in cells
    collector = []
    chunks    = CHR.chunks_from_text cell, markup_options
    #.....................................................................................................
    for chunk in chunks
      csg = chunk[ 'csg' ]
      rsg = chunk[ 'rsg' ]
      #...................................................................................................
      ### If character set is Unicode or Jizura, display characters with proper font selection markup: ###
      switch csg
        #.................................................................................................
        when 'u'
          switch rsg
            when 'u-cjk-idc', 'u-geoms', 'u-arrow', null # `null` is a mistake really
              for chr in chunk[ 'text' ]
                idc = ids_translations[ chr ]
                ### TAINT we'll probably use jizura font with standard IDCs in standard positions ###
                if false # idc?
                  collector.push "<span class='jzr jzr-idc'>".concat idc, '</span>'
                else
                  collector.push "<span class='u u-cjk-idc'>".concat chr, '</span>'
            else
              collector.push '<span class="'.concat csg, ' ', rsg, '">', chunk[ 'text' ], '</span>'
        #.................................................................................................
        when 'jzr'
          chrs  = CHR.chrs_from_text chunk[ 'text' ], markup_options
          for chr in chrs
            cid = CHR.cid_from_chr chr, markup_options
            collector.push '<span class="'.concat csg, ' ', rsg, '">', chr, '</span>'
            collector.push "<span class='zero'>&jzr#x#{cid.toString 16};</span>"
        #   chrs  = CHR.chrs_from_text chunk[ 'text' ], markup_options
        #   for chr in chrs
        #     cid   = CHR.cid_from_chr chr, markup_options
        #     # info  = CHR._analyze cid, 'jzr'
        #     # xncr  = info[ 'xncr' ]
        #     # DIV ".jzr-sprite.jzr-#{cid.toString 16}"
        #     collector.push "<div class='jzr-sprite jzr-#{cid.toString 16}'></div>"
        #.................................................................................................
        else
          ### Otherwise, display characters as FNCRs with `chr-ref` class: ###
          chrs  = CHR.chrs_from_text chunk[ 'text' ], markup_options
          for chr in chrs
            cid   = CHR.cid_from_chr chr, markup_options
            # fncr  = CHR._as_fncr csg, cid
            # collector.push "<span class='chr-ref'>#{fncr}</span>"
            collector.push """
              <span class='chr-ref'><!--
                --><span class='csg'><span class='zero'>&amp;</span>#{csg}</span><!--
                --><span class='cid'><span class='zero'>#x</span>#{cid.toString 16}<!--
                --><span class='zero'>;</span></span></span>"""
    #.....................................................................................................
    R.push collector.join ''
  #.......................................................................................................
  return R.join '\t'


#-----------------------------------------------------------------------------------------------------------
@get_languagecode_etc = ( O ) ->
  tainted_languagecode = O[ 'languagecode' ]
  [ languagecode
    translate     ] = LANGUAGE.get_languagecode_and_translator_with_fallback tainted_languagecode
  if tainted_languagecode isnt languagecode
    log TRM.red '©29f', O[ 'rqid' ], "language has been corrected from #{rpr tainted_languagecode} to #{rpr languagecode}"
  else
    log TRM.green '©29f', O[ 'rqid' ], "language has been set to #{rpr languagecode}"
  language_class    = ".#{languagecode}"
  #.........................................................................................................
  _ = RENDERABLE ( text ) =>
    SPAN language_class, translate text
    return null
  #.........................................................................................................
  return [ languagecode, language_class, translate, _ ]


#===========================================================================================================
# TEMPLATES
#-----------------------------------------------------------------------------------------------------------
@main = RENDERABLE ( O ) ->
  [ languagecode
    language_class
    translate
    _             ] = @get_languagecode_etc O
  #.........................................................................................................
  query_input_options =
    type:           'search'
    name:           'q'
    id:             'q'
    placeholder:    "XXX"
    class:          'field'
    # tabindex:       '1'
  #.........................................................................................................
  q = O[ 'last-query' ][ 'q' ]
  if q?
    query_input_options[ 'value' ] = q
    page_style  = 'resultspage'
  else
    page_style  = 'frontpage'
  #.........................................................................................................
  DOCTYPE 5
  HTML =>
    #.......................................................................................................
    HEAD =>
      META charset: 'utf-8'
      TITLE O[ 'title' ]
      ( META name: 'description', content: O[ 'description' ] ) if O[ 'description' ]?
      LINK rel: 'stylesheet', href: '/public/cssnormalize-min.css'
      LINK rel: 'stylesheet', href: '/public/mingkwai.css'
      LINK rel: 'stylesheet', href: '/public/font-awesome-4.0.0/css/font-awesome.css'
      LINK rel: 'shortcut icon', href: '/favicon.ico?v=4'
      SCRIPT src: '/public/jquery-1.10.2.min.js'
      # SCRIPT src: '/public/merge-sort-master/merge-sort.js'
      # SCRIPT src: '/public/mixitup-1.5.4/src/jquery.mixitup.js'
      SCRIPT src: '/public/github_com_carhartl_jquery-cookie/jquery.cookie.js'
      SCRIPT src: '/public/coffeenode-tagtool/main.js'
      SCRIPT src: '/public/mingkwai.js'
      #.....................................................................................................
      COFFEESCRIPT =>
        BLAIDDRWG         = {}
        window.BLAIDDRWG  = BLAIDDRWG
        log               = console.log.bind console
        # Array::sort       = [].mergeSort
        BLAIDDRWG.update_result_count = ->
          log "BLAIDDRWG.update_result_count is not implemented"
        #...................................................................................................
        ( $ document ).ready =>
          ( $ '.remove' ).remove()
          log 'ready'
          # log 'languagecode:', $.cookie 'languagecode'
          # mixitup_options =
          #   # targetSelector: '.mix',
          #   # filterSelector: '.filter',
          #   sortSelector:         '.sort'
          #   buttonEvent:          'click'
          #   # effects:              ['fade','scale']
          #   effects:              []
          #   listEffects:          null
          #   easing:               'snap'
          #   layoutMode:           'list'
          #   targetDisplayGrid:    'inline-block'
          #   targetDisplayList:    'block'
          #   gridClass:            ''
          #   listClass:            ''
          #   transitionSpeed:      500
          #   showOnLoad:           'all'
          #   sortOnLoad:           null # [ 'data-dsid', 'desc', ]
          #   multiFilter:          false
          #   filterLogic:          'or'
          #   resizeContainer:      true
          #   minHeight:            0
          #   failClass:            'fail'
          #   perspectiveDistance:  '3000'
          #   perspectiveOrigin:    '50% 50%'
          #   animateGridList:      true
          #   onMixLoad:            null
          #   onMixStart:           null
          #   onMixEnd:             null
          # log ( $ '#results' ).mixitup mixitup_options
    #.......................................................................................................
    BODY ".#{page_style}.#{languagecode}", =>
      # H1 -> if O[ 'headline' ]? then RAW O[ 'headline' ] else O[ 'title' ]
      DIV '#language-selector', =>
        TEXT translate '#LANGUAGE'
        ### TAINT use languages and codes as provided in template options ###
        UL =>
          LI => A 'data-languagecode': 'en_US', 'English'
          LI => A 'data-languagecode': 'ja_JP', '日本語'
          LI => A 'data-languagecode': 'zh_CN', '普通话'
          LI => A 'data-languagecode': 'zh_TW', '國語'
      DIV '#opener', =>
        A '#homelink', href: '/', tabindex: '10000', =>
          IMG '#typewriter-small', alt: '明快打字機 MingKwai Typewriter', src: '/public/lin-yutangs-mingkwai-typewriter/mingkwai-color-small.png'
          IMG '#logo', alt: '明快搜字機 MingKwai Type Tool', src: '/public/mingkwai-title.png'
        #.....................................................................................................
        DIV '#q-form-wrapper', =>
          FORM '#q-form', =>
            DIV '#q-wrapper', =>
              INPUT query_input_options
              BUTTON '#search-button', type: 'submit', alt: ( translate 'SEARCH' ), => I '.fa.fa-search'
            #...............................................................................................
            DIV '#ds-selector', =>
              #.............................................................................................
              DIV '.ds-item.ds-cycle', =>
                BUTTON "#ds-cycle", =>
                  I '.fa.fa-circle'
                  I '.fa.fa-adjust'
                  I '.fa.fa-circle-o', translate 'SELECT ALL'
                  _ "CYCLE SELECTION"
              #.............................................................................................
              for gid, name of DSREGISTRY[ 'groupname-by-gid' ]
                DIV '.ds-item', =>
                  cbx_options =
                    name: 'dg'
                    type: 'checkbox'
                    value: gid
                  if O[ 'gids'][ gid ] then cbx_options[ 'checked' ] = 'checked'
                  INPUT "##{gid}", cbx_options
                  LABEL for: gid, =>
                    SPAN '.ds-id.ds-gid', gid
                    SPAN '.ds-name.ds-groupname', translate name
              #.............................................................................................
              for dsid, ds_info of DSREGISTRY[ 'ds-infos' ]
                DIV '.ds-item', =>
                  name        = ds_info[ 'name' ]
                  sigil       = ds_info[ 'sigil' ]
                  cbx_options =
                    name: 'ds'
                    type: 'checkbox'
                    value: dsid
                  if O[ 'dsids'][ dsid ] then cbx_options[ 'checked' ] = 'checked'
                  INPUT "##{dsid}", cbx_options
                  LABEL for: dsid, =>
                    SPAN '.ds-id.ds-dsid', dsid
                    SPAN '.ds-name', name
              #.............................................................................................
              DIV '.ds-item', =>
                name        = 'db'
                sigil       = 'db'
                cbx_options =
                  name:   'db'
                  type:   'checkbox'
                  value:  'db'
                if O[ 'db'] then cbx_options[ 'checked' ] = 'checked'
                INPUT "#db", cbx_options
                LABEL for: 'db', =>
                  SPAN '.ds-id.ds-dsid', 'db'
                  SPAN '.ds-name', translate 'MOJIKURA DATABASE'
              #.............................................................................................
              # SCRIPT '.remove', "BLAIDDRWG.initialize_ds_state()"
      #.....................................................................................................
      if page_style is 'resultspage'
        # DIV '#results-message', "##{O[ 'request-count' ]}; dt: #{O[ 'dt' ]}ms"
        # UL =>
        #   LI '.sort', 'data-sort': 'data-result-nr', 'data-order': 'desc',    "result-nr desc"
        #   LI '.sort', 'data-sort': 'data-result-nr', 'data-order': 'asc',     "result-nr asc"
        #   LI '.sort', 'data-sort': 'data-dsid',      'data-order': 'desc',    "dsid desc"
        #   LI '.sort', 'data-sort': 'data-dsid',      'data-order': 'asc',     "dsid asc"
        #   LI '.sort', 'data-sort': 'data-line-nr',   'data-order': 'desc',    "line-nr desc"
        #   LI '.sort', 'data-sort': 'data-line-nr',   'data-order': 'asc',     "line-nr asc"
        #   LI '.sort', 'data-sort': 'default',        'data-order': 'asc',     "default"
        #   LI '.sort', 'data-sort': 'random',                                  "random"
        DIV '#results-wrapper', =>
          DIV '.results-message', =>
            SPAN '#result-count', "0"
            RAW " results (#{O[ 'dt' ]} seconds)"
          DIV '#results', => COMMENT O[ 'cut-here-mark' ]
      #.....................................................................................................
      else
        DIV '#typewriter', =>
          A class: 'nolinkmark', target: '_blank', href: 'http://en.wikipedia.org/wiki/Chinese_typewriter', =>
            img_options =
              alt:    translate "LINYUTANG MINGKWAI TYPEWRITER"
              title:  translate "LINYUTANG MINGKWAI TYPEWRITER"
              src:    '/public/lin-yutangs-mingkwai-typewriter/mingkwai-color.png'
              width:  400
            IMG img_options
        COMMENT O[ 'cut-here-mark' ]
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@result_row = RENDERABLE ( O ) ->
  #.........................................................................................................
  switch O[ 'result-type' ]
    #.......................................................................................................
    when 'text'
      [ route
        line_nr
        finds   ]         = O[ 'result' ]
      TR '.result', =>
        # TD route
        # TD O[ 'result-nr' ]
        TD line_nr
        TD finds.join ' '
    #.......................................................................................................
    when 'ds'
      #.....................................................................................................
      [ route
        line_nr
        finds   ]   = O[ 'result' ]
      result_nr     = O[ 'result-nr' ]
      dsid          = O[ 'dsid' ]
      ds_info       = DSREGISTRY[ 'ds-infos' ][ dsid ]
      ds_name       = ds_info[ 'name' ]
      #.....................................................................................................
      entry_options =
        'data-result-nr': result_nr
        'data-dsid':      dsid
        'data-line-nr':   line_nr
      #.....................................................................................................
      DIV '.result.mix', entry_options, =>
        # SPAN '.field.meta-field.result-nr',  result_nr
        SPAN '.field.meta-field.dsid',       dsid
        SPAN '.field.meta-field.line-nr',    line_nr
        SPAN '.field', =>
          isa_match = no
          # log TRM.lime '©55t', rpr finds
          for find in finds
            if find.length > 0
              find  = @_markup_text find
              # log TRM.cyan '©55t', rpr find
              # cells = find.split /\t/g,
              if isa_match
                find = find.replace /\t/g, "</span></span>\t<span class='field'><span class='match'>"
                SPAN '.match', => RAW find
              else
                find = find.replace /\t/g, "</span></span>\t<span class='field'><span>"
                SPAN '.field', => RAW find
            isa_match = not isa_match
    #.......................................................................................................
    when 'db'
      #.....................................................................................................
      entries       = O[ 'result' ]
      result_nr     = O[ 'result-nr' ]
      dsid          = O[ 'dsid' ]
      line_nr       = 0
      #.....................................................................................................
      entry_options =
        'data-result-nr': result_nr
        'data-dsid':      dsid
        'data-line-nr':   line_nr
      #.....................................................................................................
      for entry in entries
        keys = ( name for name of entry ).sort()
        #...................................................................................................
        for key in keys
          continue if key[ 0 ] is '_'
          line_nr  += 1
          value     = entry[ key ]
          #.................................................................................................
          if TYPES.isa_list value
            for sub_value, sub_idx in value
              DIV '.result.mix', entry_options, =>
                SPAN '.field.meta-field.result-nr',  result_nr
                SPAN '.field.meta-field.dsid',       dsid
                SPAN '.field.meta-field.line-nr',    line_nr
                SPAN '.field', "#{key}##{sub_idx}:"
                SPAN '.field', "#{rpr sub_value}"
          else
            DIV '.result.mix', entry_options, =>
              SPAN '.field.meta-field.result-nr',  result_nr
              SPAN '.field.meta-field.dsid',       dsid
              SPAN '.field.meta-field.line-nr',    line_nr
              SPAN '.field', "#{key}:"
              SPAN '.field', "#{rpr value}"
    #.......................................................................................................
    else
      DIV '#server-error', "unknown results type: #{rpr O[ 'result-type' ]}"

#-----------------------------------------------------------------------------------------------------------
@update_result_count = RENDERABLE ( O ) ->
  SCRIPT '.remove', "BLAIDDRWG.update_result_count( #{O[ 'result-count' ]} )"

#-----------------------------------------------------------------------------------------------------------
@refuse = RENDERABLE ( O ) ->
  [ languagecode
    language_class
    translate
    _             ] = @get_languagecode_etc O
  duration          = MOMENT.duration O[ 'ms-to-wait' ]
  #.........................................................................................................
  DIV _ O[ 'reason' ]
  #.........................................................................................................
  if duration.asMinutes() < 1
    DIV "Please try again in #{Math.floor duration.asSeconds() + 0.5} seconds."
  else
    DIV "Please try again #{duration.humanize true}."





