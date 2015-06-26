Db = require 'db'
Plugin = require 'plugin'

exports.client_trackScore = (score) !->
	bestScore = Db.shared.get('bestScore')||0
	if score>bestScore
		Db.shared.set('bestScore', score)
		Db.shared.set('bestUserId', Plugin.userId())
