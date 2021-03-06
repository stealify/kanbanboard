exports.SideNavigationView = class SideNavigationView extends Backbone.View

  className: 'side-navigation-view'

  animating: false
  lastAnimation: null

  events:
    'click .navigation-item': '_onNavigate'
    'mouseenter': '_onMouseOver'
    'mouseleave': '_onMouseOut'

  initialize: (options) ->
    @render(options.initSelectedPath)

  render: (initSelectedPath) ->
    for item in @collection
      @$el.append itemTemplate(item)

    @$('#'+initSelectedPath).addClass 'selected' # selecting the item after refresh screen

    #TODO fix this hack
    setTimeout(@_onMouseOut, 1000)

  _onNavigate: (event) ->
    navigationPath = event.target.id
    @$('.navigation-item').removeClass 'selected'
    @$('#'+navigationPath).addClass 'selected'
    Backbone.history.navigate(navigationPath, {trigger: true})

  _onMouseOver: ->
    if @animating
      @lastAnimation = 'hover'
      return

    @animating = true
    @$el.animate({left: '-3px'}, 200, 'swing', =>
      @animating = false
      if @lastAnimation is 'leave'
        @lastAnimation = null
        @_onMouseOut()
    )

  _onMouseOut: =>
    if @animating
      @lastAnimation = 'leave'
      return

    @animating = true
    move = @$el.width() - 20
    @$el.animate({left: "-#{move}px"}, 200, 'swing', =>
      @animating = false
    )

itemTemplate = (config) ->
  """
  <div id="#{config.path}" class="navigation-item">#{config.template}</div>
  """
