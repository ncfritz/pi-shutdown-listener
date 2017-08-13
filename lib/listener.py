import atexit
import os
import RPi.GPIO as GPIO
import signal
import sys
import threading
import time

from ConfigParser import ConfigParser
from subprocess import call


class ShutdownListener:
    def __init__(self):
        config = ConfigParser()
        config.read('/usr/local/pi-shutdown-listener/etc/config.cfg')

        self.button_pin = config.getint('general', 'pin')
        self.button_timeout = config.getint('general', 'timeout')

        self.time_stamp = time.time()
        self.timer = None

    def timer_callback(self):
        if self.timer:
            self.timer.cancel()
            self.timer = None

        call(['shutdown', '-r', 'now'], shell=False)

    def button_state_changed(self, channel):
        if GPIO.input(self.button_pin) and self.timer:
            self.timer.cancel()
            self.timer = None

            call(['shutdown', '-h', 'now'], shell=False)

        elif not GPIO.input(self.button_pin) and not self.timer:
            self.timer = threading.Timer(self.button_timeout, self.timer_callback)
            self.timer.start()

    def shutdown_hook(self):
        GPIO.cleanup()

    def run(self):
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.button_pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)
        GPIO.add_event_detect(self.button_pin, GPIO.BOTH)
        GPIO.add_event_callback(self.button_pin, self.button_state_changed)

        signal.signal(signal.SIGTERM, lambda num, frame: sys.exit(0))
        atexit.register(self.shutdown_hook)


if __name__ == '__main__':
    if os.getuid() != 0:
        print 'Must be run as root'
        sys.exit(1)

    listener = ShutdownListener()
    listener.run()

    while 1:
        time.sleep(86400)
