import ctypes
from enum import Enum
from typing import Union

# Load Windows Multimedia API for joystick input
winmmdll = ctypes.WinDLL('winmm.dll')

# Load functions from winmm.dll; names are same as in .dll

# gets number of joysticks connected
joyGetNumDevs_proto = ctypes.WINFUNCTYPE(ctypes.c_uint)
joyGetNumDevs_func = joyGetNumDevs_proto(("joyGetNumDevs", winmmdll))

# gets capabilites of a specific joystick
joyGetDevCaps_proto = ctypes.WINFUNCTYPE(ctypes.c_uint, ctypes.c_uint, ctypes.c_void_p, ctypes.c_uint)
joyGetDevCaps_param = (1, "uJoyID", 0), (1, "pjc", None), (1, "cbjc", 0)
joyGetDevCaps_func = joyGetDevCaps_proto(("joyGetDevCapsW", winmmdll), joyGetDevCaps_param)

# gets position data from a specific joystick
joyGetPosEx_proto = ctypes.WINFUNCTYPE(ctypes.c_uint, ctypes.c_uint, ctypes.c_void_p)
joyGetPosEx_param = (1, "uJoyID", 0), (1, "pji", None)
joyGetPosEx_func = joyGetPosEx_proto(("joyGetPosEx", winmmdll), joyGetPosEx_param)

# indicates no error occurred
NOERROR = 0

class JoyinfoFlag(Enum):
	'''
	Flags returned by joyGetPosEx when reading controller status
	'''

	RETURNX = 0x00000001
	RETURNY = 0x00000002
	RETURNZ = 0x00000004
	RETURNR = 0x00000008
	RETURNU = 0x00000010
	RETURNV = 0x00000020
	RETURNPOV = 0x00000040
	RETURNBUTTONS = 0x0000080
	RETURNRAWDATA = 0x00000100
	RETURNPOVCTS = 0x00000200
	RETURNCENTERED = 0x00000400
	USEDEADZONE = 0x00000800
	RETURNALL = (RETURNX | RETURNY | RETURNZ | RETURNR | RETURNU | RETURNV | RETURNPOV | RETURNBUTTONS)

class JoystickCapabilities:
	'''
	Contains information about the joystick capabilities
	Represents JoystickCapabilities from winmm.dll
	'''
	SIZE_W = 728
	OFFSET_V = 4 + 32 * 2

	__slots__ = ('manufacturer_id', 'product_id', 'product_name' \
		'x_min', 'x_max', 'y_min', 'y_max', 'z_min', 'z_max', \
		'num_buttons', 'poll_period_min', 'poll_period_max', \
		'r_min', 'r_max', 'u_min', 'u_max', 'v_min', 'v_max', \
		'capabilities', 'max_axes', 'num_axes', 'max_buttons')

	def __init__(self, buffer):
		ushort_array = (ctypes.c_wchar * 2).from_buffer(buffer, 4)
		# manufacturer id, product identifier
		self.manufacturer_id, self.product_id = ushort_array

		wchar_array = (ctypes.c_wchar * 32).from_buffer(buffer, 4)
		# null-terminated product name
		self.product_name = ctypes.cast(wchar_array, ctypes.c_wchar_p).value

		uint_array = (ctypes.c_uint32 * 19).from_buffer(buffer, JoystickCapabilities.OFFSET_V)
		self.x_min, self.x_max, # min and max x-coordinate
		self.y_min, self.y_max, # min and max y-coordinate
		self.z_min, self.z_max, # min and max z-coordinate
	
		self.num_buttons, # number of joystick buttons
		self.poll_period_min, self.poll_period_max, # min and max polling frequency
	
		self.r_min, self.r_max, # min and max rudder value (4th axis)
		self.u_min, self.u_max, # min and max u-coord value (5th axis)
		self.v_min, self.v_max, # min and max v-coord value (6th axis)

		self.capabilities, # joystick capabilities flags
		self.max_axes, # max number of axes supported
		self.num_axes, # number of axes in use
		self.max_buttons = uint_array # max number of buttons supported

class JoystickInfo:
	'''
	Contains extended information about the joystick position, POV, and button state
	Represents JoystickInfo from winmm.dll
	'''

	# size of this structure in bytes
	SIZE = 52

	__slots__ = ('size', 'flags', 'x', 'y', 'z', 'r', 'u', 'v', 'buttons', 'button_number', 'pov', 'reserved_1', 'reserved_2')

	def __init__(self, buffer):
		uint_array = (ctypes.c_uint32 * (JoystickInfo.SIZE // 4)).from_buffer(buffer)
		self.size, # size of the structure
		self.flags, # flags indicating valid information in this structure

		self.x, # current x-coordinate
		self.y, # current y-coordinate
		self.z, # current z-coordinate
		self.r, # current rudder position (4th axis)
		self.u, # current u-coord value (5th axis)
		self.v, # current v-coord value (6th axis)

		self.buttons, # current state of joystick buttons: 1 < x < min(32, wMaxButtons)
		self.button_number, # number of button currently pressed
		self.pov, # current position of POV control

		self.reserved_1, # not in use
		self.reserved_2 = uint_array # not in use

def get_numdevices() -> int:
	'''
	Gets the number of joystick devices connected
	'''

	try:
		return joyGetNumDevs_func()
	except:
		return 0

def get_capabilities(id: int) -> tuple[bool, Union[JoystickCapabilities, None]]:
	'''
	Gets the capabilities of a given joystick
	'''

	ret = (False, None)

	try:
		buffer = (ctypes.c_ubyte * JoystickCapabilities.SIZE_W)()

		# parameters must be converted with ctypes to be used with dll functions
		p1 = ctypes.c_uint(id)
		p2 = ctypes.cast(buffer, ctypes.c_void_p)
		p3 = ctypes.c_uint(JoystickCapabilities.SIZE_W)

		ret_val = joyGetDevCaps_func(p1, p2, p3)
		if ret_val == NOERROR:
			ret = (True, JoystickCapabilities(buffer))
	finally:
		return ret

def read_state(id: int) -> tuple[bool, Union(JoystickInfo, None)]:
	'''
	Reads the state of a given joystick
	'''

	ret = (False, None)

	try:
		buffer = (ctypes.c_uint32 * (JoystickInfo.SIZE // 4))()
		buffer[0] = JoystickInfo.SIZE
		buffer[1] = JoyinfoFlag.RETURNALL

		p1 = ctypes.c_uint(id)
		p2 = ctypes.cast(buffer, ctypes.c_void_p)

		ret_val = joyGetPosEx_func(p1, p2)
		if ret_val == JoyinfoFlag.NOERROR:
			ret = (True, JoystickInfo(buffer))
	finally:
		return ret
