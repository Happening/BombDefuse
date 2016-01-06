Comments = require 'comments'
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
	Comments.enable
		messages:
			beat: (c) -> tr("%1 defused %2 bombs, beating %3", c.user, c.v, c.about)

	gridWidthO = Obs.create()
	Obs.observe !->
		width = Page.width()
		height = Page.height()
		gridWidthO.set Math.min(width, height) / 4

	score = Obs.create(0)
	gameRunning = Obs.create(false)
	bombs = Obs.create()
	lastBombs = [-1, -1, -1]

	selectBomb = !->
		if gameRunning.get()
			bomb = Math.round(Math.random() * 16)
			for i in [bomb..bomb+15]
				nr = i%15
				if !bombs.peek(nr) and lastBombs.indexOf(nr)<0
					# start this bomb
					bombs.set nr, true
					lastBombs.shift()
					lastBombs.push(nr)
					break

			#log 'selected bomb', bomb
			Obs.onTime 750-score.peek()*(50*(1/Math.sqrt(score.peek()+1))), selectBomb
	Obs.observe !->
		if gameRunning.get()
			selectBomb()

	Dom.div !->
		Dom.style Box: 'middle center', height: '36px'
		if gameRunning.get()
			Dom.div !->
				Dom.style fontWeight: 'bold', fontSize: '200%'
				Dom.text score.get()
		else
			Dom.div !->
				Dom.style position: 'absolute', left: 0, right: 0, top: Page.height()/2-80+'px', Box: 'center'
				Dom.div !->
					Dom.cls 'startButton'
					Dom.style textAlign: 'center', maxWidth: '240px', borderRadius: '10px', boxShadow: '0 0 10px #aaa', border: '4px solid '+Plugin.colors().highlight, padding: '10px 16px'
					Dom.div !->
						Dom.style textTransform: 'uppercase', fontWeight: 'bold', fontSize: '150%', color: Plugin.colors().highlight
						Dom.text tr("Start")
					Dom.span !->
						Dom.style color: '#aaa'
						Dom.userText tr("Defuse the red bombs\nby tapping them")
					Dom.onTap !->
						gameRunning.set true

			scores = Db.shared.ref('scores')
			sorted = (+k for k, v of scores.get() when +k).sort (a, b) -> scores.get(b) - scores.get(a)
			#log 'sorted', sorted
			better = worse = false
			mePos = sorted.indexOf Plugin.userId()
			if mePos<0 and sorted.length>1
				better = sorted[sorted.length-2]
				worse = sorted[sorted.length-1]
			else
				if mePos>0
					better = sorted[mePos-1]
				if mePos<sorted.length-1
					worse = sorted[mePos+1]
			Dom.div !->
				Dom.style Box: 'middle', Flex: 1
				for uid, k in [better, Plugin.userId(), worse] when uid
					if bScore = Db.shared.get('scores', uid)
						Dom.div !->
							Dom.style Flex: 1, padding: '0 4px', textAlign: 'center', color: (if uid is Plugin.userId() then '#000' else '')
							if mePos<0
								offset = (if k is 0 then sorted.length-1 else sorted.length)
							else
								offset = k+mePos
							Dom.b tr("%1. %2", offset, Plugin.userName(uid))
							Dom.br()
							Dom.text tr("score: %1", bScore)


	for y in [0..3] then do (y) !->
		Dom.div !->
			Dom.style Box: 'middle center'
			for x in [0..3] then do (x, y) !->
				Dom.div !->
					Dom.style Box: 'middle center', width: gridWidthO.get()+'px', height: gridWidthO.get()+'px'
					Icon.render
						data: 'bomb'
						size: gridWidthO.get()*0.9*(if bombs.get(x+(y*4)) then 1.1 else 1)
						color: if gameRunning.get() then (if bombs.get(x+(y*4)) then 'red' else 'black') else '#bbb'
					Obs.observe !->
						if bombs.get(x+(y*4))
							#log 'starting bomb'
							Obs.onTime 1000, !->
								if gameRunning.get()
									gameRunning.set false
									Server.call 'trackScore', score.get()
									Modal.show tr("Boom! Game over."), tr("You defused %1 bomb|s", score.get()), !->
										for i in [0..15]
											bombs.set i, false
										score.set(0)
					Dom.on 'touchstart mousedown', !->
						if bombs.peek(x+y*4)
							bombs.set(x+y*4, false)
							score.incr()

Dom.css
	'.startButton':
		backgroundColor: '#fff'
	'.startButton.tap':
		backgroundColor: '#ddd'
