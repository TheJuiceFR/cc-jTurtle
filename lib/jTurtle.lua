--[[

jTurtle API

v2.2.9

By The Juice

Free to distribute/alter
so long as proper credit to original
author is maintained.

Direct help requests, issue reports, and
suggestions to thejuiceirl@gmail.com

TODO: getItem
TODO: putItem
TODO: placeItem
TODO: getmethods
TODO: help

]]

local dir=0	--	0=south, 1=west, 2=north, 3=east
local pos={0,0,0}
local gpsav=true
if gps.locate()==nil then gpsav=false end


function getPos()
	return pos[1],pos[2],pos[3],dir
end

function getHome()
	local f=fs.open("/cfg/jTurtle/home.json",'r')
	local o
	if f~=nil then
		o=textutils.unserialiseJSON(f.readLine())
		f.close()
	end
	
	if type(o)=="table" then
		return o.pos[1],o.pos[2],o.pos[3],o.dir
	else
		return 0,0,0,0
	end
end


local function setDir(I)
	dir=I%4
end

local function addDir(I)
	setDir(dir+I)
end

if gpsav then
	local bx,by,bz=gps.locate()
	pos={bx,by,bz}

	while turtle.forward()~=true do
		turtle.turnRight()
	end

	local ax,ay,az=gps.locate()

	turtle.back()

	if ax>bx then
		dir=3
	elseif ax<bx then
		dir=1
	elseif az>bz then
		dir=0
	elseif az<bz then
		dir=2
	else
		error("IDK, this isn't supposed to crash here.")
	end
	
else
	local bx,by,bz,bd=getHome()
	
	pos={bx,by,bz}
	dir=bd
end

local function forward()
	res,err=turtle.forward()
	if res then
		if dir==0 then
			pos[3]=pos[3]+1
		elseif dir==1 then
			pos[1]=pos[1]-1
		elseif dir==2 then
			pos[3]=pos[3]-1
		else
			pos[1]=pos[1]+1
		end
		sleep(.51)
	end
	return res,err
end

local function back()
	res,err=turtle.back()
	if res then
		if dir==0 then
			pos[3]=pos[3]-1
		elseif dir==1 then
			pos[1]=pos[1]+1
		elseif dir==2 then
			pos[3]=pos[3]+1
		else
			pos[1]=pos[1]-1
		end
		sleep(.51)
	end
	return res,err
end

local function up()
	res,err=turtle.up()
	if res then
		pos[2]=pos[2]+1
		sleep(.51)
	end
	return res,err
end

local function down()
	res,err=turtle.down()
	if res then
		pos[2]=pos[2]-1
		sleep(.51)
	end
	return res,err
end

local function turnRight()
	res,err=turtle.turnRight()
	if res then
		addDir(1)
		sleep(.51)
	end
	return res,err
end

local function turnLeft()
	res,err=turtle.turnLeft()
	if res then
		addDir(-1)
		sleep(.51)
	end
	return res,err
end


local function doNothing()
	return true
end




function setHome(x,y,z,d)
	local f=fs.open("/cfg/jTurtle/home.json",'w')
	local tex={pos={x,y,z},dir=d}
	f.write(textutils.serializeJSON(tex))
	f.close()
end

function turn(d,lengt)
	local n
	if lengt==nil then
		n=1
	else
		n=lengt
	end
	local func
	if d=="r" then
		func=turnRight
	elseif d=="l" then
		func=turnLeft
	else
		error(tostring(d).." is not a valid direction, try: 'r' 'l'")
	end
	for x=1,n do
		func()
	end
	return true
end

function dig(d)
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

function place(d,itemName)
	local _,rea=selectItem(itemName)
	if rea=="missing" then
		return false,"No items to place"
	end
	
	if d=="f" or d==nil then
		return turtle.place()
	elseif d=="u" then
		return turtle.placeUp()
	elseif d=="d" then
		return turtle.placeDown()
	else
		error(tostring(d).." is not a valid direction, try: 'f' 'u' 'd'")
	end
end

function move(d,leng)
	if leng==nil then leng=1 end
	if jTurtle.fuel()<leng then
		return false,leng,"fuel"
	end
	
	local func
	if d=="f" or d==nil then
		func=forward
	elseif d=="b" then
		func=back
	elseif d=="u" then
		func=up
	elseif d=="d" then
		func=down
	else
		error(tostring(d).." is not a valid direction, try: 'f' 'b' 'u' 'd'")
	end
	for n=1,leng do
		local tries=0
		while not func() do
			tries=tries+1
			sleep(.5)
			if tries>=3 then
				return false,(leng-n)+1,"obst"
			end
		end
	end
	return true,0
end

function tunnel(d,lengt,di1,di2)
	local leng
	if lengt==nil then
		leng=1
	else
		leng=lengt
	end
	if jTurtle.fuel()<leng then
		return false,leng,"fuel"
	end
	
	local func=doNothing
	local digfunc=doNothing
	local digfunc1=doNothing
	local digfunc2=doNothing
	
	if d=="f" or d==nil then
		func=forward
		digfunc=turtle.dig
		digfunc1=turtle.digDown
		digfunc2=turtle.digUp
	elseif d=="b" then
		func=back
		digfunc1=turtle.digDown
		digfunc2=turtle.digUp
	elseif d=="u" then
		func=up
		digfunc=turtle.digUp
		digfunc1=turtle.dig
	elseif d=="d" then
		func=down
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





function turnTo(d)
	local sd=dir
	if (d-sd)%4==2 then
		turn('r',2)
	elseif (d-sd)%4==1 then
		turn('r',1)
	elseif (d-sd)%4==3 then
		turn('l',1)
	elseif (d-sd)%4==0 then

	else
		error("input out of range, must be >=0 and <=3 and an integer")
	end	
end

function moveTo(x,y,z)
	repeat
		local sx,sy,sz,sd=getPos()
		if y==nil then
		elseif sy>y then
			move('d',sy-y)
		elseif sy<y then
			move('u',y-sy)
		end
		if x==nil then
		elseif sx>x then
			turnTo(1)
			move('f',sx-x)
		elseif sx<x then
			turnTo(3)
			move('f',x-sx)
		end
		if z==nil then
		elseif sz>z then
			turnTo(2)
			move('f',sz-z)
		elseif sz<z then
			turnTo(0)
			move('f',z-sz)
		end
		sx,sy,sz,sd=getPos()
	until sx==x and sy==y and sz==z
end





function selectItem(name)
	if type(name)=="string" then
		if getItemDetail(turtle.getSelectedSlot()).name~=name then
			local n=1
			while getItemDetail(n).name~=name and n<16 do
				n=n+1
			end
			if getItemDetail(n).name==name then
				turtle.select(n)
				return true
			else
				return false,"missing"
			end
		else
			return true
		end
	elseif type(name)=='number' and name==math.floor(name) then
		name=(name-1)%16+1
		turtle.select(name)
	end
end

function getItemDetail(slot)
	local _,rea=selectItem(slot)
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

function equipItem(side,name)
	local _,rea=selectItem(name)
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

function unequipItem(side)
	local _,rea=selectItem("minecraft:air")
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

function fuel()
	return turtle.getFuelLevel()
end

function maxFuel()
	return turtle.getFuelLimit()
end

function refuel(amount,item)
	local fl=fuel()
	if type(amount)~="number" then
		amount=maxFuel()-fl
	end
	
	local t=1
	if type(item)~="number" then t=16 end
	for n=1,t do
		if item then
			local _,res=selectItem(item)
			if res=="missing" then
				return false,"missing"
			end
		end
		repeat
			local res=turtle.refuel(1)
		until fuel()>=maxFuel() or res==false
		if not item then
			selectItem(turtle.getSelectedSlot()+1)
		end
	end
	if type(amount)~="number" or fuel()-fl>=amount then
		return true
	else
		return false,amount-(fuel()-fl)
	end
end
