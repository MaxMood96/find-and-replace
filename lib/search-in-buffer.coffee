{View} = require 'space-pen'
Editor = require 'editor'
$ = require 'jquery'
Point = require 'point'
SearchModel = require './search-model'
SearchResultsView = require './search-results-view'

module.exports =
class SearchInBufferView extends View

  @activate: -> new SearchInBufferView

  @content: ->
    @div class: 'search-in-buffer overlay from-top mini', =>
      @div class: 'find-container', =>
        @div class: 'btn-group pull-right btn-toggle', =>
          @button outlet: 'regexOptionButton', class: 'btn btn-mini', '.*'
          @button outlet: 'caseSensitiveOptionButton', class: 'btn btn-mini', 'Aa'

        @div class: 'find-editor-container', =>
          @subview 'miniEditor', new Editor(mini: true)

  detaching: false

  initialize: ->
    rootView.command 'search-in-buffer:display-find', @showFind
    rootView.command 'search-in-buffer:display-replace', @showReplace

    rootView.command 'search-in-buffer:find-previous', @findPrevious
    rootView.command 'search-in-buffer:find-next', @findNext

    #@miniEditor.on 'focusout', => @detach() unless @detaching
    @on 'core:confirm', => @confirm()
    @on 'core:cancel', => @detach()

    @searchModel = new SearchModel
    rootView.eachEditor (editor) =>
      if editor.attached and not editor.mini
        editor.underlayer.append(new SearchResultsView(@searchModel, editor))

  detach: ->
    return unless @hasParent()

    @detaching = true
    
    @searchModel.deactivate()

    if @previouslyFocusedElement?.isOnDom()
      @previouslyFocusedElement.focus()
    else
      rootView.focus()

    super

    @detaching = false

  attach: =>
    unless @hasParent()
      @previouslyFocusedElement = $(':focus')
      rootView.append(this)

    @searchModel.activate()
    @miniEditor.focus()

  confirm: =>
    @search()
    @findNext()
    #rootView.getActiveView().focus()

  showFind: =>
    @attach()

  showReplace: =>

  search: ->
    pattern = @miniEditor.getText()
    @searchModel.search(pattern, @getFindOptions())

  findPrevious: =>
    @jumpToSearchResult('findPrevious')

  findNext: =>
    @jumpToSearchResult('findNext')

  jumpToSearchResult: (functionName) ->
    editor = rootView.getActiveView()
    editSession = editor.activeEditSession

    bufferRange = @searchModel.getResultsForId(editor.id)[functionName](editSession.getSelectedBufferRange())
    editSession.setSelectedBufferRange(bufferRange, autoscroll: true) if bufferRange

  getFindOptions: ->
    {
      regex: false
      caseSensitive: false
      inWord: false
      inSelection: false
    }
