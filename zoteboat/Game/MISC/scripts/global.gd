extends Node

var map_holder = MapHolder.new()

var map = Map.new()

var player = Player.new()

var dialogue = Dialogue.new()

var navigation_agent_2d = NavigationAgent2D.new()

var vignette: ColorRect = VignetteNode.new()

func hasSignal(node : Node, signalName : String) -> bool:
	var signalList = node.get_signal_list()
	for signalDictionary in signalList:
		if signalDictionary.name == signalName:
			return true
	return false
