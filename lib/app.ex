defmodule App do
	use Application

	def start(_type, _args) do
		Socket.open(6667)
	end
end