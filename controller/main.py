from time import sleep
from input import Input

def main():
	controller = Input()

	while True:
		print(controller.get_xbox_state())
		sleep(0.25)

if __name__ == "__main__":
	main()
	