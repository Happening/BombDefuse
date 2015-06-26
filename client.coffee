Db = require 'db'
Dom = require 'dom'
Modal = require 'modal'
Icon = require 'icon'
Obs = require 'obs'
Plugin = require 'plugin'
Page = require 'page'
Server = require 'server'
Ui = require 'ui'
{tr} = require 'i18n'

exports.render = !->
	{width, height} = Dom.viewport.get()
	gridWidth = Math.min(width, height-150) / 4

	score = Obs.create(0)
	interval = Obs.create(0)
	bombs = Obs.create()

	selectBomb = !->
		bomb = Math.round(Math.random() * 16)
		for i in [bomb..bomb+15]
			nr = if i>15 then i-15 else i
			log 'i, nr', i, nr
			if !bombs.get(nr)
				# start this bomb
				to = setTimeout !->
					clearTimeout interval.get()
					interval.set(0)
					for k, v of bombs.get()
						clearTimeout(v) if v
					Server.call 'trackScore', score.get()
					Modal.show tr("Boom! Game over."), tr("You defused %1 bomb|s", score.get()), !->
						for i in [0..15]
							bombs.set(i, 0)
						score.set(0)
				, 1000
				bombs.set(nr, to)
				break

		log 'selected bomb', bomb
		intervalTo = setTimeout !->
			selectBomb()
		, 750 - score.get()*10
		interval.set(intervalTo)

	Dom.div !->
		Dom.style Box: 'middle center', minHeight: '40px', marginBottom: '10px'
		if interval.get()
			Dom.div !->
				Dom.style fontWeight: 'bold'
				Dom.text tr("Your score: %1", score.get())
		else
			Ui.button tr("Start"), !->
				selectBomb()

		Dom.div !->
			Dom.style Flex: 1, textAlign: 'right'
			bestUserId = Db.shared.get('bestUserId')
			bestScore = Db.shared.get('bestScore')
			Dom.text tr("Best score: %1 (by %2)", bestScore, Plugin.userName(bestUserId))

	for y in [0..3] then do (y) !->
		Dom.div !->
			Dom.style Box: 'middle center'
			for x in [0..3] then do (x, y) !->
				log 'y, x', y, x
				Dom.div !->
					Dom.style width: gridWidth+'px', height: gridWidth+'px'
					Icon.render
						data: 'bomb'
						size: gridWidth*0.9
						color: if bombs.get(x+(y*4)) then 'red' else 'gray'
					Dom.on 'touchstart mousedown', !->
						log 'touched bomb ', x, y, x+y*4
						if to = bombs.get(x+y*4)
							clearTimeout to
							bombs.set(x+y*4, 0)
							score.incr()
