Template.main.onCreated ->
	self = @
	self.autorun ->
		roomId = FlowRouter.getParam 'roomId'
		self.subscribe 'room', roomId

Template.mainTable.onCreated ->
	self = @
	self.autorun ->
		roomId = FlowRouter.getParam 'roomId'
		self.subscribe 'room', roomId

Template.mainTable.onRendered ->
	self = @
	self.autorun ->
		Uno.Cards.find(Uno.Rooms.findOne(FlowRouter.getParam('roomId'))?.topCardId ? null).observe
			changed: ->
				$('#topCard').css('transition', '')
				$('#topCard').css('transform', 'scale(20)')
			added: (doc) ->
				$('#topCard').css('transition', 'all 0.3s ease')
				$('#topCard').css('transform', 'scale(1)')

Template.main.onRendered ->
	$('.button-collapse').sideNav
		menuWidth: 300
		edge: 'left'
		closeOnClick: true

	interact('svg[data-draggable=true]').draggable
		inertia: true
		#restrict:
		#	restriction: '.container-fluid'
		#	endOnly: true
		onstart: (e) ->
			if Uno.canPlayCard FlowRouter.getParam('roomId'), Meteor.userId(), $(e.target).data('id')
				$('#inner').css('background-color', '#3D3')	
			else
				$('#inner').css('background-color', '#D33')	
			$(e.target).css('transition', '')
			$('#inner').css('opacity', '1')
		onend: (e) ->
			$(e.target).css('transform', 'translate(0px, 0px)')
			$(e.target).css('transition', 'all 0.3s linear')
			e.target.setAttribute('data-x', 0)
			e.target.setAttribute('data-y', 0)
			$('#inner').css('opacity', '0')
		onmove: (e) ->
			x = (parseFloat(e.target.getAttribute('data-x')) || 0) + e.dx
			y = (parseFloat(e.target.getAttribute('data-y')) || 0) + e.dy
			$(e.target).css('transform', "translate(#{x}px, #{y}px)")
			e.target.setAttribute('data-x', x)
			e.target.setAttribute('data-y', y)
	
	interact('#inner,#table svg').dropzone
		accept: 'svg[data-draggable=true]'
		ondrop: (e) ->
			if Uno.Rooms.findOne(FlowRouter.getParam('roomId'))?.started
				Meteor.call 'Uno.playCard', FlowRouter.getParam('roomId'), Meteor.userId(), $(e.relatedTarget).data('id')
			
Template.card.helpers
	hexColor: ->
		if @color == 'red' then return '#FF5555'
		else if @color == 'yellow' then return '#FFAA00'
		else if @color == 'green' then return '#00AA00'
		else if @color == 'blue' then return '#5555FF'
		else return ''
	isType: (type) -> @type == type

Template.main.events
	'click #enterRoom': ->
		$('#enterRoom').attr('disabled', true)
		Meteor.call 'Uno.enterRoom', FlowRouter.getParam('roomId'), Meteor.userId(), (e, ret) ->
			$('#enterRoom').attr('disabled', false)
	'click #leaveRoom': ->
		$('#leaveRoom').attr('disabled', true)
		Meteor.call 'Uno.leaveRoom', FlowRouter.getParam('roomId'), Meteor.userId(), (e, ret) ->
			$('#leaveRoom').attr('disabled', false)
	'click #drawCard': ->
		$('#drawCard').attr('disabled', true)
		Meteor.call 'Uno.drawCard', FlowRouter.getParam('roomId'), Meteor.userId(), (e, ret) ->
			$('#drawCard').attr('disabled', false)
	'click #startRoom': ->
		$('#startRoom').attr('disabled', true)
		Meteor.call 'Uno.startRoom', FlowRouter.getParam('roomId'), (e, ret) ->
			$('#startRoom').attr('disabled', false)
	'click #closeRoom': ->
		$('#closeRoom').attr('disabled', true)
		Meteor.call 'Uno.closeRoom', FlowRouter.getParam('roomId'), (e, ret) ->
			$('#closeRoom').attr('disabled', false)

Template.main.helpers
	cards: -> Uno.Cards.find {roomId: FlowRouter.getParam('roomId'), userId: Meteor.userId()}
	users: -> Meteor.users.find {_id: {$in: Uno.Rooms.findOne(FlowRouter.getParam('roomId'))?.userIds ? []}}
	room: -> Uno.Rooms.findOne FlowRouter.getParam('roomId')
	lastPlays: -> (Uno.Rooms.findOne(FlowRouter.getParam('roomId'))?.lastPlays ? []).reverse().slice(0, 5)
	topCard: -> Uno.Cards.findOne(Uno.Rooms.findOne(FlowRouter.getParam('roomId'))?.topCardId ? null)
	amIInThisRoom: -> _.contains(Uno.Rooms.findOne(FlowRouter.getParam('roomId'))?.userIds ? [], Meteor.userId())

Template.mainTable.helpers
	lastPlays: -> (Uno.Rooms.findOne(FlowRouter.getParam('roomId'))?.lastPlays ? []).reverse().slice(0, 10)
	topCard: -> Uno.Cards.findOne(Uno.Rooms.findOne(FlowRouter.getParam('roomId'))?.topCardId ? null)
