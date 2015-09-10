###
FlowRouter.route '/',
	name: '/'
	action: ->
		BlazeLayout.render 'model',
			content: 'main'
###

FlowRouter.route '/room/:roomId',
	name: '/room'
	action: ->
		BlazeLayout.render 'model',
			content: 'main'

FlowRouter.route '/table/:roomId',
	name: '/table'
	action: ->
		BlazeLayout.render 'model',
			content: 'mainTable'
