defmodule Marvin.SmartThing.SmartThingSupervisor do

	use Supervisor
	require Logger
	alias Marvin.SmartThing.{CNS, PFCortex, Memory, PerceptorsSupervisor, Perception, MotivatorsSupervisor, BehaviorsSupervisor, ActuatorsSupervisor, Motivation, Behaviors, Actuation, InternalClock, PG2Communicator}
	import Marvin.SmartThing.Utils, only: [platform_dispatch: 1]

	@name __MODULE__

	### Supervisor Callbacks

	@spec start_link() :: {:ok, pid}
	@doc "Start the smart thing supervisor, linking it to its parent supervisor"
  def start_link() do
		Logger.info("Starting #{@name}")
		{:ok, _pid} = Supervisor.start_link(@name, [], [name: @name])
	end 

	@spec init(any) :: {:ok, tuple}
	def init(_) do
		children = [	
		 	worker(CNS, []),
		 	worker(Memory, []),
			worker(PFCortex, []),
			worker(InternalClock, []),
		 	worker(PG2Communicator, []),
		 	supervisor(ActuatorsSupervisor, []),
		 	supervisor(BehaviorsSupervisor, []),
		 	supervisor(MotivatorsSupervisor, []),
		 	supervisor(PerceptorsSupervisor, [])
		]
		opts = [strategy: :one_for_one]
		supervise(children, opts)
	end

	@doc "Start the robot's perception"
	def start_perception() do
		Logger.info("Starting perception")
		start_perceptors()
	end

	@doc "Start the robot's execution"
	def start_execution() do
		Logger.info("Starting execution")
 		start_actuators()
		start_behaviors()
		start_motivators()
	end

	### Private
	
	defp start_perceptors() do
		Perception.perceptor_configs()
		|> Enum.each(&(PerceptorsSupervisor.start_perceptor(&1)))
	end

  defp start_motivators() do
		Motivation.motivator_configs()
		|> Enum.each(&(MotivatorsSupervisor.start_motivator(&1)))
	end

  defp start_behaviors() do
		Behaviors.behavior_configs()
		|> Enum.each(&(BehaviorsSupervisor.start_behavior(&1)))
	end

  defp start_actuators() do
		Actuation.actuator_configs()
		|> Enum.each(&(ActuatorsSupervisor.start_actuator(&1)))
	end

  defp all_used_senses() do
    MapSet.new(
      Perception.used_senses() ++ Motivation.used_senses() ++ Behaviors.used_senses())
    |> MapSet.to_list()
  end
  
end
	
