Comments = require 'comments'
Db = require 'db'
Event = require 'event'
Plugin = require 'plugin'

exports.getTitle = !-> # prevents title input from showing up when adding the plugin

exports.client_trackScore = (score) !->
	userId = Plugin.userId()
	oldSorted = (+k for k, v of Db.shared.get('scores') when +k).sort (a, b) -> Db.shared.get('scores', b) - Db.shared.get('scores', a)
	oldPos = oldSorted.indexOf userId

	oldScore = Db.shared.get('scores', userId)||0
	if score>oldScore
		Db.shared.set('scores', userId, score)
	Db.shared.incr('attempts', userId, 1)

	newSorted = (+k for k, v of Db.shared.get('scores') when +k).sort (a, b) -> Db.shared.get('scores', b) - Db.shared.get('scores', a)
	newPos = newSorted.indexOf userId
	runnerUp = newSorted[newPos+1]
	if runnerUp and (newPos isnt oldPos or +oldScore is Db.shared.get('scores', runnerUp)) and score>Db.shared.get('scores', runnerUp)
		Comments.post
			s: 'beat'
			u: Plugin.userId()
			a: runnerUp
			v: score
			pushText: Plugin.userName() + " just defused "+score+" bombs, beating your best score!"
			path: '/'
