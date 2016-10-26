{TicketView} = require './TicketView'

exports.KanbanColumnView = class KanbanColumnView extends Backbone.View

  className: 'kanban-column'

  size: null

  columnClass: null
  columnTitle: null
  ticketCollection: null
  statuses: null
  color: null

  ticketViews: []

  initialize: (options) ->
    {@columnClass, @columnTitle, @statuses, @ticketCollection, @size, @color} = options
    @listenTo @ticketCollection, 'sync', @_renderTickets

    @render()

  render: ->
    @$el.css('width', @size + '%') if @size
    @$el.addClass @columnClass if @columnClass
    @$el.css('box-shadow', "0px 20px 5px #{@color} inset") if @color

    @$el.append(template(@columnTitle))

  _renderTickets: ->
    $ticketsEl = @$('.kanban-column-content')
    $ticketsEl.empty()

    for ticket in @ticketCollection.models
      if ticket.get('status').name in @statuses
        view = new TicketView(ticketData: ticket)
        @ticketViews.push(view)
        $ticketsEl.append view.el

    return @

  remove: ->
    for view in @ticketViews
      view.remove();

    super arguments...

template = (columnTitle) ->
  """
  <div class="kanban-column-title">#{columnTitle}</div><div class="kanban-column-content"></div>
  """
