return {
   engineHandlers = {
      onPlayerAdded = function(player)
         player:sendEvent("loaded", nil)
      end,
   },
}
