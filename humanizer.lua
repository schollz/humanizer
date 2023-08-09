-- humanizer
nodes={}
num_nodes=5
node_main=3
Node={}

function Node:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Node:init()
  self.sleep_time=clock.get_beat_sec()
  self.on_count=0
  self.disable_clock=self.disable_clock or false
  self.td=0
  self.tlast=clock.get_beat_sec()*clock.get_beats()
  self.trig=false
  self.x={}
  for i=1,128 do
    table.insert(self.x,0)
  end
  if not self.disable_clock then
    clock.run(function()
      while true do
        self:trigger()
        local c=params:get("coupling")/100
        if nodes[node_main]~=nil then
          local sleep_time=nodes[node_main].td
          -- add randominess
          sleep_time=sleep_time+(1-c)*math.random(-100,100)/1000
          local delta=nodes[node_main].tlast-self.tlast
          if delta>nodes[node_main].td/2 then
            delta=delta-nodes[node_main].td
          elseif delta<-1*nodes[node_main].td/2 then
            delta=delta+nodes[node_main].td
          end
          print(delta)
          local v=delta*8
          v=v>math.abs(2) and 0 or v
          table.remove(self.x,128)
          table.insert(self.x,1,v)
          sleep_time=sleep_time+(delta*c)
          sleep_time=(sleep_time>3 and clock.get_beat_sec() or sleep_time)
          clock.sleep(sleep_time)
        else
          clock.sleep(1)
        end
      end
    end)
  end
end

function Node:trigger()
  self.trig=true
  local t=clock.get_beat_sec()*clock.get_beats()
  self.td=t-self.tlast
  self.tlast=t
  self.on_count=14
end

function Node:update()
  if self.on_count>0 then
    self.on_count=self.on_count-(params:get("clock_tempo")>120 and 3 or 2)
  end
  self.trig=false
end

function Node:redraw()
  -- local yoffset=3
  -- if self.id>1 then
  --   for i,v in ipairs(self.x) do
  --     if i>1 then
  --       screen.level(2)
  --       screen.move(i-1,yoffset+(self.id*12)+(self.x[i-1])*6-8)
  --       screen.line_rel(i,yoffset+(self.id*12)+(self.x[i])*6-8)
  --       screen.stroke()
  --       screen.level(10)
  --       screen.move(i-1,yoffset+(self.id*12)+(self.x[i-1])*6-8)
  --       screen.line(i,yoffset+(self.id*12)+(self.x[i])*6-8)
  --       screen.stroke()
  --     end
  --   end
  -- end
  screen.level(self.on_count)
  screen.rect(24*self.id-12,24,10,10)
  screen.fill()
end

function init()
  params:add_number("coupling","coupling",0,100,0)

  for i=1,num_nodes do
    nodes[i]=Node:new{id=i,disable_clock=i==3}
  end

  -- main clock
  clock.run(function()
    while true do
      clock.sync(1)
      nodes[node_main]:trigger()
    end
  end)

  -- other clocks
  clock.run(function()
    while true do
      clock.sleep(1/15)
      for i=1,num_nodes do
        nodes[i]:update()
      end
      redraw()
    end
  end)
end

function enc(k,d)
  if k==1 then
  elseif k==2 then
    params:delta("clock_tempo",d)
  elseif k==3 then
    params:delta("coupling",d)
  end
end

function key(k,z)
end

function redraw()
  screen.clear()
  screen.aa(0)
  screen.line_width(1)
  screen.blend_mode(5)

  for i=1,num_nodes do
    nodes[i]:redraw()
  end

  screen.level(15)
  screen.move(2,5)
  screen.text(params:get("clock_tempo"))
  screen.move(124,5)
  screen.text_right(string.format("%d%%",params:get("coupling")))

  screen.update()
end
