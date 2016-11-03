exports.TicketFilterView = class TicketFilterView extends Backbone.View

  className: 'ticket-filter-view'

  viewState: null
  stateAttribute: null
  animating: false
  ticketField: null
  position: null
  title: null
  allValues: null

  events:
    'click .filter-item': '_onFilterClick'
    'click .all': '_selectAll'
    'click .none': '_selectNone'
    'mouseenter': '_onMouseOver'
    'mouseleave': '_onMouseOut'

  initialize: (options) ->
    {@ticketField, @viewState, @stateAttribute, @position, @title} = options

    if @collection instanceof Backbone.Collection
      @listenTo @collection, 'sync', @render
    else
      @render()

  render: () ->
    @$el.empty();

    @$el.addClass @position
    @$el.append template(@title)

    properties = @_retreiveAllValues()

    data = {}
    data[@stateAttribute] = @allValues
    @viewState.set(data, {silent: true}) # silent only for startup

    $wrapper = @$('.items-wrapper')
    for key of properties
      $wrapper.append itemTemplate({id: key, name: properties[key]})

    setTimeout(@_onMouseOut, 1000)

  _retreiveAllValues: ->

    properties = {}
    stateValue = []

    if @collection instanceof Backbone.Collection
      #if we have a ticket collection, we need to take the data from the tickets
      properties = {}
      stateValue = []
      for ticket in @collection.models
        value = ticket.get(@ticketField) || {id: '-1', name: 'unassigned'}
        unless properties[value.id]
          properties[value.id] = value.name
          stateValue.push value.id+''
    else
      #if we have a static collection
      for value in @collection
        key = value.id
        properties[value.id] = value.name
        stateValue.push value.id

    @allValues = stateValue
    return properties

  _onFilterClick: (event) ->
    selectedFilter = @$('#'+event.target.id)
    if selectedFilter.hasClass 'selected'
      selectedFilter.removeClass 'selected'
      @viewState.set(@stateAttribute, @viewState.get(@stateAttribute).filter((column) => return column isnt event.target.id))
    else
      selectedFilter.addClass 'selected'
      columns = @viewState.get(@stateAttribute)
      @viewState.set(@stateAttribute, columns.concat [event.target.id])

  _onMouseOver: =>
    return if @animating
    @animating = true
    @$el.animate({right: '-3px'}, 200, 'swing', => @animating = false)

  _onMouseOut: =>
    return if @animating
    @animating = true
    move = @$el.width() - 20
    @$el.animate({right: "-#{move}px"}, 200, 'swing', => @animating = false)

  _selectAll: ->
    @$('.filter-item').addClass 'selected'
    @viewState.set(@stateAttribute, @allValues)

  _selectNone: ->
    @$('.filter-item').removeClass 'selected'
    @viewState.set(@stateAttribute, [])


template = (title) ->
  """
  <div class="title">#{title}</div><div class="select"><span class="all">All</span><span class="none">None</span></div><div class="items-wrapper"></div>
  """

itemTemplate = (config) ->
  """
  <div id="#{config.id}" class="filter-item selected">#{config.name}</div>
  """
