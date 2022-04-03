from time import sleep
import pygame

class CoordinatePair(object):
	'''
	Represents an (x, y) coordinate pair.
	'''

	__slots__ = ('x', 'y')
	x: float
	y: float

	def __init__(self, x: float, y: float):
		self.x = x
		self.y = y

class RawControllerState(object):
	'''
	Represents the unmapped state of any joystick
	'''

	__slots__ = ('axes', 'balls', 'buttons', 'hats')

	axes: list[float]
	balls: list[tuple[float, float]]
	buttons: list[bool]
	hats: list[tuple[float, float]]

	def __init__(
		self,
		axes: list[float],
		balls: list[tuple[float, float]],
		buttons: list[bool],
		hats: list[tuple[float, float]]):

		self.axes = axes
		self.balls = balls
		self.buttons = buttons
		self.hats = hats

class XboxControllerState(object):
	"""
	Represents the input state of the controller.
	"""

	__slots__ = ('left_stick', 'right_stick', 'left_trigger', 'right_trigger', 'a', 'b', 'x', 'y', 'left_bumper', 'right_bumper', 'back_button', 'start_button', 'left_stick_in', 'right_stick_in', 'guide_button', 'd_pad_vertical', 'd_pad_horizontal')
	
	def __init__(
		self,
		left_stick: CoordinatePair,
		right_stick: CoordinatePair,
		left_trigger: float,
		right_trigger: float,
		a: bool,
		b: bool,
		x: bool,
		y: bool,
		left_bumper: bool,
		right_bumper: bool,
		back_button: bool,
		start_button: bool,
		left_stick_in: bool,
		right_stick_in: bool,
		guide_button: bool,
		d_pad_vertical: float,
		d_pad_horizontal: float):

		self.left_stick = left_stick
		self.right_right = right_stick

		self.left_trigger = left_trigger
		self.right_trigger = right_trigger

		self.a = a
		self.b = b
		self.x = x
		self.y = y

		self.left_bumper = left_bumper
		self.right_bumper = right_bumper

		self.back_button = back_button
		self.start_button = start_button

		self.left_stick_in = left_stick_in
		self.right_stick_in = right_stick_in

		self.guide_button = guide_button

		self.d_pad_vertical = d_pad_vertical
		self.d_pad_horizontal = d_pad_horizontal

class Input(object):
	'''
	Manager for receiving input from a single joystick or controller
	'''

	__slots__ = ('joystick')

	joystick: pygame.joystick.Joystick

	def __init__(self) -> None:
		# Initialize the pygame joystick module
		pygame.joystick.init()

		joystick_count = pygame.joystick.get_count()

		# If there are no joysticks connected, wait until one is connected
		while joystick_count == 0:
			print("No joystick detected, waiting 1s")
			sleep(1)
			joystick_count = pygame.joystick.get_count()
		
		print("Found {} joysticks".format(joystick_count))

		for i in range(joystick_count):
			joystick = pygame.joystick.Joystick(1)
			joystick.init()

			try:
				joystick_id = joystick.get_instance_id()
			except AttributeError:
				joystick_id = joystick.get_id()
			
			name = joystick.get_name()
			print("Initialied joystick {} ({})".format(name, joystick_id))

			## TODO detect the correct joystick, this could break controls completely
			self.joystick = joystick
	
	def get_xbox_state(self) -> XboxControllerState:
		state = self.get_state()

		return XboxControllerState(
			CoordinatePair(state.axes[0], state.axes[1]),
			CoordinatePair(state.axes[3], state.axes[4]),
			state.axes[2],
			state.axes[5],
			state.buttons[0],
			state.buttons[1],
			state.buttons[2],
			state.buttons[3],
			state.buttons[4],
			state.buttons[5],
			state.buttons[6],
			state.buttons[7],
			state.buttons[8],
			state.buttons[9],
			state.buttons[10],
			state.axes[6],
			state.axes[7],
		)
	
	def get_state(self) -> RawControllerState:
		'''
		Read the current joystick state and any input events
		'''

		for event in pygame.event.get():
			print(event)

		axes = [] # [int]: float
		numaxes = self.joystick.get_numaxes()
		for i in range(numaxes):
			axis = self.joystick.get_axis(i)
			axes[i] = axis

		balls = []
		numballs = self.joystick.get_numballs()
		for i in range(numballs):
			ball = self.joystick.get_ball(i)
			balls[i] = ball
		
		buttons = []
		numbuttons = self.joystick.get_numbuttons()
		for i in range(numbuttons):
			button = self.joystick.get_button(i)
			buttons[i] = button
		
		hats = []
		numhats = self.joystick.get_numhats()
		for i in range(numhats):
			hat = self.joystick.get_hat(i)
			hats[i] = hat
		
		return RawControllerState(axes, balls, buttons, hats)
