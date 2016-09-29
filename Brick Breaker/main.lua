---------------------------------------------------------------------------------------------------
										  -- BRICK BREAKER --
----------------------------------------------------------------------------------------------------

display.setStatusBar( display.HiddenStatusBar )

----------------------------------------------------------------------------------------------------

-- Required Libraries:
local physics = require ( "physics" )
local particleDesigner = require( "particleDesigner" )

----------------------------------------------------------------------------------------------------

-- Forward Definitions:
local height, width = display.contentHeight, display.contentWidth
local background
local ball
local paddle
local bottom_wall
local top_wall
local left_wall
local right_wall
local score_display
local life_1
local life_2
local life_3
local brick_destroy_soud = audio.loadSound( 'blast.mp3' )
local game_over_sound = audio.loadSound( 'explosion.mp3' )
local background_music = audio.loadStream( 'background_music.mp3' )
local brick_list = {}
local levels = {
	{ number_of_rows = 1, number_of_columns = 7 },
	{ number_of_rows = 2, number_of_columns = 7 },
	{ number_of_rows = 3, number_of_columns = 7 },
	{ number_of_rows = 4, number_of_columns = 7 },
	{ number_of_rows = 5, number_of_columns = 7 },
	{ number_of_rows = 6, number_of_columns = 7 },
	{ number_of_rows = 7, number_of_columns = 7 },
	{ number_of_rows = 8, number_of_columns = 7 },
	{ number_of_rows = 9, number_of_columns = 7 },
	{ number_of_rows = 10, number_of_columns = 7 }
}
local counter
local iterator = 1
local score = 0

----------------------------------------------------------------------------------------------------

-- Main Function:
function main()
	setUpPhysics()
	createBackground()
	createLives()
	createWalls()
	createBricks()
	createBall()
	createPaddle()
	createScore()
	startGame()
end

----------------------------------------------------------------------------------------------------

-- Clear Game Function:
function clearGame()
	audio.stop()
	ball:removeSelf()
	ball = nil
	paddle:removeSelf()
	paddle = nil
	bottom_wall:removeSelf()
	bottom_wall = nil
	top_wall:removeSelf()
	top_wall = nil
	left_wall:removeSelf()
	left_wall = nil
	right_wall:removeSelf()
	right_wall = nil
	background:removeSelf()
	background = nil
	score_display:removeSelf()
	score_display = nil
	for i = #brick_list, 1, -1 do
		local delete_brick = table.remove( brick_list, i ) 
		delete_brick:removeSelf()
		delete_brick = nil
	end
end

----------------------------------------------------------------------------------------------------

-- End Game Function:
function endGame()
	clearGame()
	background = display.newImageRect( "game_over.jpg", width, height )
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	audio.play( game_over_sound )
end

----------------------------------------------------------------------------------------------------

-- Set Up Physics Function:
function setUpPhysics()
	physics.start()
	physics.setDrawMode( "normal" )
	physics.setGravity( 0, 0 )
end

----------------------------------------------------------------------------------------------------

-- Create Background Function:
function createBackground()
	background = display.newImageRect( "background.png", width, height )
	background.x = display.contentCenterX
	background.y = display.contentCenterY
end

----------------------------------------------------------------------------------------------------

-- Create Lives Function:
function createLives()
	life_1 = particleDesigner.newEmitter( "fire_II.json" )
	life_1.x = width - 300
	life_1.y = 10
	life_2 = particleDesigner.newEmitter( "fire_II.json" )
	life_2.x = width - 270
	life_2.y = 10
	life_3 = particleDesigner.newEmitter( "fire_II.json" )
	life_3.x = width - 240
	life_3.y = 10
end

----------------------------------------------------------------------------------------------------

-- Create Score Function:
function createScore()
	score_display = display.newText( "", width - 20, 05, mainFont, mainFontSize )
	score_display.text = score
end

----------------------------------------------------------------------------------------------------

-- Create Paddle Function:
function createPaddle()
	local paddle_width = 100
	local paddle_height = 10
	paddle = display.newImageRect( "paddle.png", paddle_width, paddle_height )
	paddle.x = width/2 - paddle_width/2
	paddle.y = height - 50
	physics.addBody( paddle, "static", {friction=0, bounce=1.1} )

	local  movePaddle = function(event)
			paddle.x = event.x
	end
	Runtime:addEventListener( "touch", movePaddle )
end

----------------------------------------------------------------------------------------------------

-- Create Ball Function:
function createBall()
	local ball_radius = 10
	ball = particleDesigner.newEmitter( "fire.json" )
	ball.x = width/2
	ball.y = height/2
	physics.addBody( ball, "dynamic", {friction=0, bounce = 1, radius=ball_radius} )

	ball.collision = function(self, event)
		if(event.phase == "ended") then
			if(event.other.type == "destructible") then
				event.other.type = "indestructible"
				event.other.isSensor = true
				event.other.isVisible = false
				audio.play(brick_destroy_soud)
				counter = counter - 1
				score = score + 10
				score_display.text = score
			end

			onComplete = checkBricks()
			if(event.other.type == "bottom_wall") then
				self:removeSelf()
				local onTimerComplete = function(event)
					createBall()
					startGame()
				end

				if (life_1 ~= nil and life_2 ~= nil and life_3 ~= nil) then
					life_3:removeSelf()
					life_3 = nil
					timer.performWithDelay( 500, onTimerComplete, 1 )

				elseif (life_1 ~= nil and life_2 ~= nil and life_3 == nil) then
					life_2:removeSelf()
					life_2 = nil
					timer.performWithDelay( 500, onTimerComplete, 1 )

				elseif (life_1 ~= nil and life_2 == nil and life_3 == nil) then
					life_1:removeSelf()
					life_1 = nil
					timer.performWithDelay( 500, onTimerComplete, 1 )

				elseif (life_1 == nil and life_2 == nil and life_3 == nil) then
					Runtime:removeEventListener( "touch", movePaddle )
					endGame()
				end
			end
		end
	end
	ball:addEventListener( "collision", ball )
end

----------------------------------------------------------------------------------------------------

-- Start Game Function:
function startGame()
	ball:setLinearVelocity( 75, 250 )	
end

----------------------------------------------------------------------------------------------------

-- Create Bricks Function:
function createBricks()
	local brick_width = 40
	local brick_height = 20
	local number_of_rows = levels[iterator].number_of_rows
	local number_of_columns = levels[iterator].number_of_columns
	local topLeft = {x= width*.56 - (brick_width * number_of_columns )/2, y= 50}

	local row
	local column
	for row = 0, number_of_rows - 1 do
		for column = 0, number_of_columns - 1 do
			local brick = display.newImageRect( "brick.png", brick_width, brick_height )
			table.insert(brick_list, brick)
			brick.index = #brick_list
			brick.x = topLeft.x + (column * brick_width)
			brick.y = topLeft.y + (row * brick_height),
			brick:setFillColor( 1, 1, 1 )
			brick.type = "destructible"
			physics.addBody( brick, "static", {friction=0, bounce = 1} )
		end
	end
	counter = levels[iterator].number_of_rows * 7

	if (iterator < 10 ) then
		iterator = iterator+1
	end
end

----------------------------------------------------------------------------------------------------

-- Create Walls Function:
function createWalls()
	right_wall = display.newRect( width, height/2 + 100, 10, height + 200)
	left_wall = display.newRect( 0, height/2 + 100 ,10, height + 200 )
	top_wall = display.newRect( width/2, 0, width, 10 )
	bottom_wall = display.newRect( width/2, height + 100, width, 10 )

	physics.addBody( right_wall, "static", {friction = 0, bounce = 1} )
	physics.addBody( left_wall, "static", {friction = 0, bounce = 1} )
	physics.addBody( top_wall, "static", {friction = 0, bounce = 1} )
	physics.addBody( bottom_wall, "static", {friction = 0, bounce = 1} )
	bottom_wall.type = "bottom_wall"

	right_wall.isVisible = false
	left_wall.isVisible = false
	top_wall.isVisible = false
	bottom_wall.isVisible = false
end

----------------------------------------------------------------------------------------------------

-- Check Bricks Function:
function checkBricks()
	if (counter <= 0) then
			for i = #brick_list, 1, -1 do
				local delete_brick = table.remove( brick_list, i )
				delete_brick:removeSelf()
			end
			paddle:removeSelf()
			bottom_wall:removeSelf()
			top_wall:removeSelf()
			left_wall:removeSelf()
			right_wall:removeSelf()
			ball:removeSelf()
		local reset = function ()
			onComplete = createWalls()
			onComplete = createBricks()
			onComplete = createBall()
			onComplete = createPaddle()
			onComplete = startGame()
		end
		timer.performWithDelay(100, reset, 1)
	end
end

----------------------------------------------------------------------------------------------------

-- Run Program:
main()
audio.play( background_music, {loops = -1, channel = 1, fadeIn = 500} )

----------------------------------------------------------------------------------------------------