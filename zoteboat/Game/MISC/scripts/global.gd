extends Node

var map_holder = MapHolder.new()

var map = Map.new()

var player = Player.new()

func hasSignal(node : Node, signalName : String) -> bool:
	var signalList = node.get_signal_list()
	for signalDictionary in signalList:
		if signalDictionary.name == signalName:
			return true
	return false
