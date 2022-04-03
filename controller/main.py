from queue import Queue
from threading import Thread
from time import sleep

from input import input_main

def main():
	to_input_queue = Queue()
	from_input_queue = Queue()

	input_thread = Thread(target=input_main, args=(to_input_queue, from_input_queue))
	input_thread.start()

	while True:
		sleep(1)
		to_input_queue.put("test1")

if __name__ == "__main__":
	main()