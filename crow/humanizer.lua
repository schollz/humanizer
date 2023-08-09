-- humanizer
nodes={}
num_nodes=5
node_main=1
Node={}
coupling=0

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
  self.is_output=self.is_output or false
  self.td=0
  self.tlast=clock.get_beat_sec()*clock.get_beats()
  self.trig=false
  self.x={}
  for i=1,128 do
    table.insert(self.x,0)
  end
  if self.is_output then
    clock.run(function()
      while true do
        self:trigger()
        local c=coupling/100
        if nodes[node_main]~=nil then
          local sleep_time=nodes[node_main].td
          -- add randomness
          -- TODO make gaussian?
          sleep_time=sleep_time+(1-c)*math.random(-100,100)/1000
          local delta=nodes[node_main].tlast-self.tlast
          if delta>nodes[node_main].td/2 then
            delta=delta-nodes[node_main].td
          elseif delta<-1*nodes[node_main].td/2 then
            delta=delta+nodes[node_main].td
          end
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
  -- TODO
  -- crow pulse here
end

function init()
  for i=1,num_nodes do
    nodes[i]=Node:new{id=i,is_output=i~=1}
  end

  -- TODO
  -- crow input clock detection does trigger

  -- TODO
  -- crow input two sets the coupling

  -- -- main clock
  -- clock.run(function()
  --   while true do
  --     clock.sync(1)
  --     nodes[node_main]:trigger()
  --   end
  -- end)
end
