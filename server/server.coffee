Meteor.publishComposite 'room', (roomId) ->
	userId = @userId
	if userId
		return {
			find: -> Uno.Rooms.find {_id: roomId}
			children: [
				{find: (room) -> Uno.Cards.find {$or: [{_id: room.topCardId}, {_id: {$in: room?.cardIds ? []}, roomId: roomId, userId: userId}]}}
				{find: (room) -> Meteor.users.find {_id: {$in: room?.userIds ? []}}}
			]
		}
	else
		return @ready()
