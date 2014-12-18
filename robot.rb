#!/usr/bin/env ruby

require 'io/console'
require 'pi_piper'
include PiPiper

@left_go_pin = PiPiper::Pin.new(pin: 17, direction: :out)
@left_direction_pin = PiPiper::Pin.new(pin: 4, direction: :out)
@right_go_pin = PiPiper::Pin.new(pin: 10, direction: :out)
@right_direction_pin = PiPiper::Pin.new(pin: 25, direction: :out)

led1 = PiPiper::Pin.new(pin: 7, direction: :out)
led2 = PiPiper::Pin.new(pin: 8, direction: :out)

sw1 = PiPiper::Pin.new(pin: 11, direction: :in, pull: :down)
oc1 = PiPiper::Pin.new(pin: 22, direction: :out)

@left_go_pin.off
@right_go_pin.off

@left_direction_pin.off
@right_direction_pin.off

led1.off
led2.off
oc1.off


def show_help
  puts <<EOS
w    forward
s    reverse
a    rotate left
d    rotate right
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

loop do
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

stop

puts "bye!"

