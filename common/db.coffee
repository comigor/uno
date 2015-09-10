@Uno or= {}
Uno.Rooms = new Meteor.Collection '__uno_rooms'
Uno.Hands = new Meteor.Collection '__uno_hands'
Uno.Cards = new Meteor.Collection '__uno_cards'

###
	1. Logged players enter a room, eg /room/wydHdzfahJafmNeHG
	2. Any player can start game clicking on start button
	3. System gets the room (wydHdzfahJafmNeHG) and players ids
###

Meteor.methods
	'Uno.enterRoom': (roomId, userId) ->
		Uno.Rooms.upsert {_id: roomId}, {$addToSet: {userIds: userId}}
		return roomId

	'Uno.leaveRoom': (roomId, userId) ->
		Uno.Rooms.upsert {_id: roomId}, {$pull: {userIds: userId}}
		return roomId

	'Uno.restartRoom': (roomId) ->
		Uno.Rooms.remove roomId
		Uno.Cards.remove {roomId: roomId}
		Uno.startRoom roomId
		return roomId

	'Uno.closeRoom': (roomId) ->
		Uno.Rooms.remove roomId
		Uno.Cards.remove {roomId: roomId}
		return roomId

	'Uno.startRoom': (roomId) ->
		room = Uno.Rooms.findOne roomId
		if room
			if room.userIds?.length > 1
				cardIds = Meteor.call 'Uno.generateDeck', roomId
				topCardId = cardIds.pop()
				Uno.Cards.update topCardId, {$set: {userId: 'topcard'}}
				Uno.Rooms.upsert {_id: roomId}, {$set: {cardIds: cardIds, topCardId: topCardId, started: true}, $push: {lastPlays: moment().format('HH:mm:ss') + ' - ' + 'Game has started.'}}
				_.each room.userIds, (userId) ->
					i = 0
					while i < 7
						Uno.Cards.update cardIds.pop(), {$set: {userId: userId}}
						i++
				return roomId
			else throw new Meteor.Error 'Two players are needed to start a room.'
		else throw new Meteor.Error 'Room does not exist.'

	'Uno.drawCard': (roomId, userId) ->
		user = Meteor.users.findOne userId
		room = Uno.Rooms.findOne roomId
		if room
			Uno.Rooms.update roomId, {$push: {lastPlays: moment().format('HH:mm:ss') + ' - ' + user.emails[0].address + ' has drawn a card.'}}
			cardId = _.shuffle(Uno.Cards.find({_id: {$in: room.cardIds ? []}, userId: null}).map (card) -> card._id)?[0]
			Uno.Cards.update cardId, {$set: {userId: userId}}
			return cardId
		else throw new Meteor.Error 'Room does not exist.'

	'Uno.generateDeck': (roomId) ->
		cards = []
		colors = ['red', 'yellow', 'green', 'blue']
		_.each colors, (color) ->
			numbers = [0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9]
			_.each numbers, (number) ->
				cards.push Uno.Cards.insert {type: 'number', color: color, number: number, roomId: roomId, userId: null}
			others = ['skip', 'skip', 'drawTwo', 'drawTwo', 'reverse', 'reverse']
			_.each others, (other) ->
				cards.push Uno.Cards.insert {type: other, color: color, roomId: roomId, userId: null}

			cards.push Uno.Cards.insert {type: 'wild', roomId: roomId, userId: null}
			cards.push Uno.Cards.insert {type: 'wildDrawFour', roomId: roomId, userId: null}
		return _.shuffle cards

	'Uno.playCard': (roomId, userId, cardId) ->
		if Uno.canPlayCard roomId, userId, cardId
			user = Meteor.users.findOne userId
			room = Uno.Rooms.findOne roomId
			Uno.Cards.update room.topCardId, {$set: {userId: null}}

			Uno.Rooms.update roomId, {$set: {topCardId: cardId}, $push: {lastPlays: moment().format('HH:mm:ss') + ' - ' + user.emails[0].address + ' has played a card.'}}
			Uno.Cards.update cardId, {$set: {userId: 'topcard'}}

			if Uno.Cards.find({roomId: roomId, userId: userId}).count() == 0
				Uno.Rooms.update roomId, {$set: {started: false}, $push: {lastPlays: '-- ' + moment().format('HH:mm:ss') + ' - ' + user.emails[0].address + ' has won! --'}}
			return cardId

Uno.canPlayCard = (roomId, userId, cardId) ->
	room = Uno.Rooms.findOne roomId
	card = Uno.Cards.findOne cardId
	if !room or !card then throw new Meteor.Error 'Room or card does not exist.'
	topCard = Uno.Cards.findOne room.topCardId
	if !topCard then throw new Meteor.Error 'Top card does not exist.'
	
	itsOk = false
	if _.contains(['wild', 'wildDrawFour'], card.type)
		itsOk = true
	else if _.contains(['skip', 'drawTwo', 'reverse', 'number'], card.type) and (_.contains(['wild', 'wildDrawFour'], topCard.type) or card.color == topCard.color or card.number == topCard.number)
		itsOk = true
	return itsOk
