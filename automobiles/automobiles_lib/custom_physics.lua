local min = math.min
local abs = math.abs

function automobiles_lib.physics(self)
    local friction = 0.99
	local vel=self.object:get_velocity()
		-- dumb friction
	if self.isonground and not self.isinliquid then
        --minetest.chat_send_all('okay')
		self.object:add_velocity({x=vel.x*friction-vel.x,
					  y=0,
					  z=vel.z*friction-vel.z})
	end
	
	-- bounciness
	if self.springiness and self.springiness > 0 then
		local vnew = vector.new(vel)
		
		if not self.collided then						-- ugly workaround for inconsistent collisions
			for _,k in ipairs({'y','z','x'}) do
				if vel[k]==0 and abs(self.lastvelocity[k])> 0.1 then
					vnew[k]=-self.lastvelocity[k]*self.springiness
				end
			end
		end
		
		if not vector.equals(vel,vnew) then
			self.collided = true
		else
			if self.collided then
				vnew = vector.new(self.lastvelocity)
			end
			self.collided = false
		end
		
		self.object:add_velocity(vector.subtract(vel, vnew))
	end
	
	-- buoyancy
	local surface = nil
	local surfnodename = nil
	local spos = automobiles_lib.get_stand_pos(self)
	spos.y = spos.y+0.01
	-- get surface height
	local snodepos = automobiles_lib.get_node_pos(spos)
	local surfnode = automobiles_lib.nodeatpos(spos)
	while surfnode and (surfnode.drawtype == 'liquid' or surfnode.drawtype == 'flowingliquid') do
		surfnodename = surfnode.name
		surface = snodepos.y +0.5
		if surface > spos.y+self.height then break end
		snodepos.y = snodepos.y+1
		surfnode = automobiles_lib.nodeatpos(snodepos)
	end
	self.isinliquid = surfnodename

    --normal use
    if surface then				-- standing in liquid
--		self.isinliquid = true
	    local submergence = min(surface-spos.y,self.height)/self.height
--		local balance = self.buoyancy*self.height
	    local buoyacc = (automobiles_lib.gravity*-1)*(self.buoyancy-submergence)
	    automobiles_lib.set_acceleration(self.object,
		    {x=-vel.x*self.water_drag,y=buoyacc-vel.y*abs(vel.y)*0.4,z=-vel.z*self.water_drag})
    end
end
