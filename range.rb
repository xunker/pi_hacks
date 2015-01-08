#!/usr/bin/env ruby

require 'pi_piper'
include PiPiper

@trigger_pin = PiPiper::Pin.new(pin: 14, direction: :out)
@echo_pin = PiPiper::Pin.new(pin: 15, direction: :in)

def measure
  # This method measures a distance
  @trigger_pin.on
  sleep(0.00001)
  @trigger_pin.off
  
  watchdog1 = 0
  watchdog2 = 0
  while @echo_pin.read == 0 do
    break if (watchdog1 += 1) > 1000
  end
  start = Time.now

  while @echo_pin.read == 1 do
    break if (watchdog2 += 1) > 1000
  end
  stop = Time.now

  elapsed = stop - start

  distance = (elapsed * 34300)/2
  return distance
end

def measure_average
  # This method takes 3 measurements and
  # returns the average.
  distance1 = measure
  sleep(0.1)
  distance2 = measure
  sleep(0.1)
  distance3 = measure
  distance = distance1 + distance2 + distance3
  distance = distance / 3
  return distance
end

puts "Ultrasonic Measurement"

# Set trigger to False (Low)
@trigger_pin.off

# Wrap main content in a try block so we can
# catch the user pressing CTRL-C and run the
# GPIO cleanup function. This will also prevent
# the user seeing lots of unnecessary error
# messages.
begin

  loop do
    distance = measure_average
    puts "Distance : #{sprintf("%.1f", distance)}"
    sleep(1)
  end

rescue
  # User pressed CTRL-C
  # Reset GPIO settings
  @trigger_pin.off
  raise
end

