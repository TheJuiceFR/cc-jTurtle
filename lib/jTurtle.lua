--[[

jTurtle API

v2.2.9

By The Juice

Free to distribute/alter
so long as proper credit to original
author is maintained.

Direct help requests, issue reports, and
suggestions to thejuiceirl@gmail.com

TODO: suckItem

]]

if not _JTURTLE then
	_G._JTURTLE = {
		loc = vector.new(0,0,0),
		dir = 0
	}
end

local axes = {}
   axes.up = vector.new( 0, 1, 0)
 axes.down = vector.new( 0,-1, 0)
axes.south = vector.new( 0, 0, 1)
 axes.west = vector.new(-1, 0, 0)
axes.north = vector.new( 0, 0,-1)
 axes.east = vector.new( 1, 0, 0)
 axes.none = vector.new( 0, 0, 0)

local directions = {}
directions.south = 0
 directions.west = 1
directions.north = 2
 directions.east = 3
directions.right = 1
 directions.left = -1
 directions.none = 0
directions[0] = "south"
directions[1] = "west"
directions[2] = "north"
directions[3] = "east"

local aX,aY,aZ = gps.locate()
if aX == nil then
	local f=fs.open("/var/jTurtle/pos",'r')
	if f then
		local o=textutils.unserialize(f.readAll())
		f.close()
		_JTURTLE.loc = vector.new(o.loc.x,o.loc.y,o.loc.z)
		_JTURTLE.dir = o.dir
		print("Location pulled from variable: "..tostring(_JTURTLE.loc)..", "..directions[_JTURTLE.dir])
	else
		print("Location fallen back to default: "..tostring(_JTURTLE.loc)..", "..directions[_JTURTLE.dir])
	end
else
	local aLoc=vector.new(aX,aY,aZ)
	
	while turtle.forward()~=true do
		turtle.turnRight()
	end

	local bLoc=vector.new(gps.locate())
	
	turtle.back()

	local dirVec = bLoc - aLoc
	
	
	_JTURTLE.loc = aLoc
	if dirVec == axes.south then
		_JTURTLE.dir = directions.south
	elseif dirVec == axes.west then
		_JTURTLE.dir = directions.west
	elseif dirVec == axes.north then
		_JTURTLE.dir = directions.north
	elseif dirVec == axes.east then
		_JTURTLE.dir = directions.east
	else
		error("Error in finding direction")
	end
	print("Location aquired via GPS: "..tostring(_JTURTLE.loc)..", "..directions[_JTURTLE.dir])
end






local function savePos()
	local f=fs.open("/var/jTurtle/pos",'w')
	local tex={loc=_JTURTLE.loc,dir=_JTURTLE.dir}
	f.write(textutils.serialize(tex))
	f.close()
end

local jTurtle = {}

jTurtle.directions = {
	south = directions.south,
	 west = directions.west,
	north = directions.north,
	 east = directions.east
}


function jTurtle.getPos()
	return _JTURTLE.loc, _JTURTLE.dir
end

function jTurtle.setPos(location, direction)
	assert(type(location)=="table" and location.x, "location (arg 1) must be a vector")
	assert(type(direction)=="number", "direction (arg 2) must be a number")
	location.x = math.floor(location.x)
	location.y = math.floor(location.y)
	location.z = math.floor(location.z)
	direction = math.floor(direction % 4)
	
	_JTURTLE.loc = location
	_JTURTLE.dir = direction
	savePos()
end

local function movePos(locChange, dirChange)
	assert(type(locChange)=="table" and locChange, "locationChange (arg 1) must be a vector")
	assert(type(dirChange)=="number", "directionChange (arg 2) must be a number")
	
	jTurtle.setPos(_JTURTLE.loc + locChange, _JTURTLE.dir + dirChange)
end

function jTurtle.getHome()
	local f=fs.open("/cfg/jTurtle/home",'r')
	local o
	if f~=nil then
		o = textutils.unserialise(f.readAll())
		f.close()
	end
	
	if type(o)=="table" then
		return vector.new(o.loc.x,o.loc.y,o.loc.z), o.dir
	else
		return vector.new(0,0,0), 0
	end
end

function jTurtle.setHome(location,direction)
	if location == nil then location = _JTURTLE.loc end
	if direction == nil then direction = _JTURTLE.dir end

	assert(type(location)=="table" and location.x, "location (arg 1) must be a vector or nil")
	assert(type(direction)=="number", "direction (arg 2) must be a number or nil")
	
	local f=fs.open("/cfg/jTurtle/home",'w')
	local tex={loc=location,dir=direction}
	f.write(textutils.serialize(tex))
	f.close()
end



if not _JTURTLE.rawMove then
	_JTURTLE.rawMove = {
		forward = turtle.forward,
		back = turtle.back,
		up = turtle.up,
		down = turtle.down,
		turnRight = turtle.turnRight,
		turnLeft = turtle.turnLeft
	}
	
	function turtle.forward()
		res,err=_JTURTLE.rawMove.forward()
		if res then
			movePos(axes[directions[_JTURTLE.dir]], directions.none)
		end
		return res,err
	end

	function turtle.back()
		res,err=_JTURTLE.rawMove.back()
		if res then
			movePos(-axes[directions[_JTURTLE.dir]], directions.none)
		end
		return res,err
	end

	function turtle.up()
		res,err=_JTURTLE.rawMove.up()
		if res then
			movePos(axes.up, directions.none)
		end
		return res,err
	end

	function turtle.down()
		res,err=_JTURTLE.rawMove.down()
		if res then
			movePos(axes.down, directions.none)
		end
		return res,err
	end

	function turtle.turnRight()
		res,err=_JTURTLE.rawMove.turnRight()
		if res then
			movePos(axes.none, directions.right)
		end
		return res,err
	end

	function turtle.turnLeft()
		res,err=_JTURTLE.rawMove.turnLeft()
		if res then
			movePos(axes.none, directions.left)
		end
		return res,err
	end
end



function jTurtle.turn(d,lengt)
	local n
	if lengt==nil then
		n=1
	else
		n=lengt
	end
	local func
	if d=="l" then
		func=turtle.turnLeft
	else
		func=turtle.turnRight
	end
	for x=1,n do
		func()
	end
	return true
end

function jTurtle.dig(d)
	if d=="f" or d==nil then
		return turtle.dig()
	elseif d=="u" then
		return turtle.digUp()
	elseif d=="d" then
		return turtle.digDown()
	else
		error(tostring(d).." is not a valid direction, try: 'f' 'u' 'd'")
	end
end

function jTurtle.move(d,leng)
	if leng==nil then leng=1 end
	if jTurtle.fuel()<leng then
		return false,leng,"fuel"
	end
	
	local func
	if d=="f" or d==nil then
		func=turtle.forward
	elseif d=="b" then
		func=turtle.back
	elseif d=="u" then
		func=turtle.up
	elseif d=="d" then
		func=turtle.down
	else
		error(tostring(d).." is not a valid direction, try: 'f' 'b' 'u' 'd'")
	end
	for n=1,leng do
		local tries=0
		while not func() do
			tries=tries+1
			sleep(.5)
			if tries>=3 then
				return false,n-1,"obst"
			end
		end
	end
	return true,leng
end

local function doNothing() return true end

function jTurtle.tunnel(d,leng,di1,di2)
	if type(leng)~="number" then leng=1 end
	if jTurtle.fuel()<leng then
		return false,leng,"fuel"
	end
	
	local func=doNothing
	local digfunc=doNothing
	local digfunc1=doNothing
	local digfunc2=doNothing
	
	if d=="f" or d==nil then
		func=turtle.forward
		digfunc=turtle.dig
		digfunc1=turtle.digDown
		digfunc2=turtle.digUp
	elseif d=="b" then
		func=turtle.back
		digfunc1=turtle.digDown
		digfunc2=turtle.digUp
	elseif d=="u" then
		func=turtle.up
		digfunc=turtle.digUp
		digfunc1=turtle.dig
	elseif d=="d" then
		func=turtle.down
		digfunc=turtle.digDown
		digfunc1=turtle.dig
	else
		error(d.." is not a valid direction, try: 'f' 'b' 'u' 'd'")
	end
	for n=1,leng do
		local tries=0
		digfunc()
		while not func() and tries<10 do
			tries=tries+1
			digfunc()
		end
		if di1 then
			digfunc1()
		end
		if di2 then
			digfunc2()
		end
		if tries==10 then
			return false,leng-n+1,"obst"
		end
	end
	return true,0
end





function jTurtle.turnTo(d)
	local sd=_JTURTLE.dir
	if (d-sd)%4==2 then
		jTurtle.turn('r',2)
	elseif (d-sd)%4==1 then
		jTurtle.turn('r',1)
	elseif (d-sd)%4==3 then
		jTurtle.turn('l',1)
	elseif (d-sd)%4==0 then

	else
		error("input out of range, must be >=0 and <=3 and an integer")
	end	
end

function jTurtle.moveTo(destLoc,destDir)
	while destLoc ~= jTurtle.getPos() do
		local curLoc = jTurtle.getPos()
		local dx, dy, dz = destLoc.x-curLoc.x, destLoc.y-curLoc.y, destLoc.z-curLoc.z
		
		if dy==0 then
		elseif dy>0 then
			jTurtle.move('u',dy)
		elseif dy<0 then
			jTurtle.move('d',-dy)
		end
		if dx==0 then
		elseif dx>0 then
			jTurtle.turnTo(directions.east)
			jTurtle.move('f',dx)
		elseif dx<0 then
			jTurtle.turnTo(directions.west)
			jTurtle.move('f',-dx)
		end
		if dz==0 then
		elseif dz>0 then
			jTurtle.turnTo(directions.south)
			jTurtle.move('f',dz)
		elseif dz<0 then
			jTurtle.turnTo(directions.north)
			jTurtle.move('f',-dz)
		end
	end
	
	if type(destDir)=="number" then
		jTurtle.turnTo(destDir)
	end
end




function jTurtle.fuel()
	return turtle.getFuelLevel()
end

function jTurtle.maxFuel()
	return turtle.getFuelLimit()
end

function jTurtle.getSelectedItem()
	return turtle.getSelectedSlot(), jTurtle.getItemDetail()
end

function jTurtle.selectItem(name)
	if name == nil then
		for n=1,15 do
			local detail = turtle.getItemDetail()
			if detail then
				return true
			end
			jTurtle.selectItem(turtle.getSelectedSlot() + 1)
		end
		return false
	elseif type(name)=="string" then
		if not string.find(name,":") then name = "minecraft:"..name end
		if name == "minecraft:air" then
			for n=1,15 do
				local detail = turtle.getItemDetail()
				if not detail then
					return true
				end
				jTurtle.selectItem(turtle.getSelectedSlot() + 1)
			end
			return false
		end
		
		for n=1,15 do
			local detail = turtle.getItemDetail()
			if detail and detail.name == name then
				return true
			end
			jTurtle.selectItem(turtle.getSelectedSlot() + 1)
		end
		return false
	elseif type(name)=="number" then
		name=math.floor(name-1)%16+1
		return turtle.select(name)
	end
end

function jTurtle.refuel(amount,item)
	local fl=jTurtle.fuel()
	if type(amount)~="number" then
		amount=jTurtle.maxFuel()-fl
	end
	
	local t=1
	if type(item)~="number" then t=16 end
	for n=1,t do
		if item then
			local _,res=jTurtle.selectItem(item)
			if res=="missing" then
				return false,"missing"
			end
		end
		repeat
			local res=turtle.refuel(1)
		until jTurtle.fuel()>=jTurtle.maxFuel() or res==false
		if not item then
			jTurtle.selectItem(turtle.getSelectedSlot()+1)
		end
	end
	if type(amount)~="number" or jTurtle.fuel()-fl>=amount then
		return true
	else
		return false,amount-(jTurtle.fuel()-fl)
	end
end

function jTurtle.getItemDetail(slot)
	local _,rea=jTurtle.selectItem(slot)
	if rea=="missing" then
		return false,"missing"
	end
	local d=turtle.getItemDetail()
	if d~=nil then
		return d
	else
		return {count=0,name="minecraft:air",damage=0}
	end
end

function jTurtle.equipItem(side,name)
	local _,rea=jTurtle.selectItem(name)
	if rea=="missing" then
		return false,"missing"
	end
	
	if side=='r' then
		return turtle.equipRight()
	elseif side=='l' then
		return turtle.equipLeft()
	else
		error(tostring(side).." is not a valid side, try: 'l' 'r'")
	end
end

function jTurtle.unequipItem(side)
	local _,rea=jTurtle.selectItem("minecraft:air")
	if rea=="missing" then
		return false,"noSpace"
	end
	
	if side=='r' then
		turtle.equipRight()
	elseif side=='l' then
		turtle.equipLeft()
	else
		error(tostring(side).." is not a valid side, try: 'l' 'r'")
	end
end

function jTurtle.dropItem(d, name, count)
	
	local func
	if d=='f' or d==nil then
		func = turtle.drop
	elseif d=='u' then
		func = turtle.dropUp
	elseif d=='d' then
		func = turtle.dropDown
	else
		error(tostring(side).." is not a valid side, try: 'f' 'u' 'd'")
	end
	
	if count == nil then
		if not jTurtle.selectItem(name) then return 0 end
		local numDropped = jTurtle.getItemDetail().count
		if func() then return numDropped end
		return 0
	end
	
	local numDropped = 0
	repeat
		if not jTurtle.selectItem(name) then return numDropped end
		local dropIntent = jTurtle.getItemDetail().count
		if dropIntent > count - numDropped then
			dropIntent = count - numDropped
		end
		
		local dropped = func(dropIntent)
		if dropped then numDropped = numDropped + dropIntent end
	until numDropped >= count or not dropped
	return numDropped
end

function jTurtle.suckInventory(d, name, count)
	
	local func
	local perName
	if d=='f' or d==nil then
		func = turtle.suck
		perName = "front"
	elseif d=='u' then
		func = turtle.suckUp
		perName = "top"
	elseif d=='d' then
		func = turtle.suckDown
		perName = "bottom"
	else
		error(tostring(side).." is not a valid side, try: 'f' 'u' 'd'")
	end
	
	local isInv = false
	for _,v in pairs({peripheral.getType(perName)}) do
		if v == "inventory" then isInv = true end
	end
	if not isInv then return false, "No inventory found" end
	
	
	
	
end

function jTurtle.suckDropped(d, count)
	
	local func
	if d=='f' or d==nil then
		if turtle.detect() then return false, "Block obstructing" end
		return turtle.suck()
	elseif d=='u' then
		if turtle.detectUp() then return false, "Block obstructing" end
		return turtle.suckUp()
	elseif d=='d' then
		if turtle.detectDown() then return false, "Block obstructing" end
		return turtle.suckDown()
	else
		error(tostring(side).." is not a valid side, try: 'f' 'u' 'd'")
	end
end

function jTurtle.placeItem(d, name)
	local _,rea=jTurtle.selectItem(name)
	if rea=="missing" then
		return false,"missing"
	end
	
	if d=='f' or d==nil then
		return turtle.place(count)
	elseif d=='u' then
		return turtle.placeUp(count)
	elseif d=='d' then
		return turtle.placeDown(count)
	else
		error(tostring(side).." is not a valid side, try: 'f' 'u' 'd'")
	end
end






return jTurtle
