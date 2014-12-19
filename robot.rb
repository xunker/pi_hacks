#!/usr/bin/env ruby

require 'io/console'
require 'pi_piper'
include PiPiper

@left_go_pin = PiPiper::Pin.new(pin: 17, direction: :out)
@left_go_pin.off
@left_direction_pin = PiPiper::Pin.new(pin: 4, direction: :out)
@left_direction_pin.off
@right_go_pin = PiPiper::Pin.new(pin: 10, direction: :out)
@right_go_pin.off
@right_direction_pin = PiPiper::Pin.new(pin: 25, direction: :out)
@right_direction_pin.off

@trigger_pin = PiPiper::Pin.new(pin: 14, direction: :out)
@trigger_pin.off
@echo_pin = PiPiper::Pin.new(pin: 15, direction: :in)

led1 = PiPiper::Pin.new(pin: 7, direction: :out)
led1.off
led2 = PiPiper::Pin.new(pin: 8, direction: :out)
led2.off

sw1 = PiPiper::Pin.new(pin: 11, direction: :in, pull: :down)
sw2 = PiPiper::Pin.new(pin: 9, direction: :in, pull: :down)
oc1 = PiPiper::Pin.new(pin: 22, direction: :out)
oc1.off

def show_help
  puts <<EOS
w/W    forward
s/S    reverse
a/A    rotate left
d/D   rotate right
x    exit
h/?  this text
EOS
end

def stop
  stop_left_motor
  stop_right_motor
end

def go
  start_left_motor
  start_right_motor
end

def start_left_motor
  @left_go_pin.on
end

def stop_left_motor
  @left_go_pin.off
end

def start_right_motor
  @right_go_pin.on
end

def stop_right_motor
  @right_go_pin.off
end

def set_rotate_left
  @left_direction_pin.off
  @right_direction_pin.off
end

def set_rotate_right
  @left_direction_pin.on
  @right_direction_pin.on
end

def set_forward
  @left_direction_pin.on
  @right_direction_pin.off
end

def set_reverse
  @left_direction_pin.off
  @right_direction_pin.on
end

def forward_forever
  set_forward
  go
end

def forward(duration=0.5)
  puts 'forward'
  stop
  set_forward
  go

  sleep(duration)

  stop
end

def reverse(duration=0.5)
  puts 'reverse'
  stop
  set_reverse
  go

  sleep(duration)

  stop
end

def rotate_left(duration=0.5)
  puts 'rotate left'
  stop
  set_rotate_left
  go

  sleep(duration)

  stop
end

def rotate_right(duration=0.5)
  puts 'rotate right'
  stop
  set_rotate_right
  go

  sleep(duration)

  stop
end

def measure
  # This method measures a distance
  @trigger_pin.on
  sleep(0.00001)
  @trigger_pin.off
  
  watchdog1 = 0
  watchdog2 = 0
  broken = false
  while @echo_pin.read == 0 do
    if (watchdog1 += 1) > 1000
      broken = true
      break 
    end
  end
  start = Time.now
  return 0.0 if broken

  while @echo_pin.read == 1 do
    if (watchdog2 += 1) > 1000
      broken = true
      break 
    end
  end
  stop = Time.now
  return 0.0 if broken

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

loop do
  if sw1.read == 0
    distance = measure_average
    puts "Distance : #{sprintf("%.1f", distance)}"
    clear = true
    if distance < 30.0
      puts "\tobstacle in path"
      clear = false
    end
    if sw2.read == 1
      puts "\ttoo dark"
      clear = false
    end

    if clear
      puts "\tmoving forward"
      forward_forever
    else
      puts "\treversing"
      stop
      sleep(0.5)
      reverse(0.25)
      stop
      sleep(0.5)
      rotate_left(0.25)
    end
  else
    stop
    print 'command> '
    cmd = STDIN.getch.strip
    case cmd
    when '?', 'h'
      show_help
    when 'x'
      break
    when 'w'
      forward(1)
    when 'W'
      forward(2)
    when 's'
      reverse(0.5)
    when 'S'
      reverse(1)
    when 'a'
      rotate_left(0.25)
    when 'A'
      rotate_left(1)
    when 'd'
      rotate_right(0.25)
    when 'D'
      rotate_right(1)
    else
      puts "unknown command '#{cmd}'"
    end
  end
end

stop

puts "bye!"

