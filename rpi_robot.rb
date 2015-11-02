#!/usr/bin/env ruby

require 'io/console'
require 'rpi_gpio'

PWM_DUTY_CYCLE = 35
PWM_FREQ = 50
MIN_DISTANCE = 100.0

RPi::GPIO.set_numbering :bcm

@default_speed = PWM_DUTY_CYCLE

@left_go_pin = 17
RPi::GPIO.setup @left_go_pin, as: :output
# RPi::GPIO.set_low @left_go_pin
@left_pwm = RPi::GPIO::PWM.new(@left_go_pin, PWM_FREQ)

@left_direction_pin = 4
RPi::GPIO.setup @left_direction_pin, as: :output
RPi::GPIO.set_low @left_direction_pin

@right_go_pin = 10
RPi::GPIO.setup @right_go_pin, as: :output
# RPi::GPIO.set_low @right_go_pin
@right_pwm = RPi::GPIO::PWM.new(@right_go_pin, PWM_FREQ)

@right_direction_pin = 25
RPi::GPIO.setup @right_direction_pin, as: :output
RPi::GPIO.set_low @right_direction_pin

@trigger_pin = 14
RPi::GPIO.setup @trigger_pin, as: :output
RPi::GPIO.set_low @trigger_pin

@echo_pin = 15
RPi::GPIO.setup @echo_pin, as: :input

@led1 = 7
RPi::GPIO.setup @led1, as: :output
RPi::GPIO.set_low @led1

@led2 = 8
RPi::GPIO.setup @led2, as: :output
RPi::GPIO.set_low @led2

@sw1 = 11
RPi::GPIO.setup @sw1, as: :input

@sw2 = 9
RPi::GPIO.setup @sw2, as: :input

@oc1 = 22
RPi::GPIO.setup @oc1, as: :output
RPi::GPIO.set_low @oc1


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

def go(duty_cycle=@default_speed)
  start_left_motor(duty_cycle)
  start_right_motor(duty_cycle)
end

def start_left_motor(duty_cycle=@default_speed)
  @left_pwm.start(duty_cycle)
  # RPi::GPIO.set_high @left_go_pin
end

def stop_left_motor
  @left_pwm.stop
  # RPi::GPIO.set_low @left_go_pin
end

def start_right_motor(duty_cycle=@default_speed)
  @right_pwm.start(duty_cycle)
  # RPi::GPIO.set_high @right_go_pin
end

def stop_right_motor
  @right_pwm.stop
  # RPi::GPIO.set_low @right_go_pin
end

def set_rotate_left
  RPi::GPIO.set_low @left_direction_pin
  RPi::GPIO.set_low @right_direction_pin
end

def set_rotate_right
  RPi::GPIO.set_high @left_direction_pin
  RPi::GPIO.set_high @right_direction_pin
end

def set_forward
  RPi::GPIO.set_low @left_direction_pin
  RPi::GPIO.set_high @right_direction_pin
end

def set_reverse
  RPi::GPIO.set_high @left_direction_pin
  RPi::GPIO.set_low @right_direction_pin
end

def forward_forever
  set_forward
  go
end

def forward(duration: 0.5, speed: @default_speed)
  puts 'forward'
  stop
  set_forward
  go(speed)

  sleep(duration)

  stop
end

def reverse(duration: 0.5, speed: @default_speed)
  puts 'reverse'
  stop
  set_reverse
  go(50)

  sleep(duration)

  stop
end

def rotate_left(duration: 0.5)
  puts 'rotate left'
  stop
  set_rotate_left
  go(100)

  sleep(duration)

  stop
end

def rotate_right(duration: 0.5)
  puts 'rotate right'
  stop
  set_rotate_right
  go(100)

  sleep(duration)

  stop
end

def measure
  # This method measures a distance
  RPi::GPIO.set_high @trigger_pin
  sleep(0.00001)
  RPi::GPIO.set_low @trigger_pin

  watchdog1 = 0
  watchdog2 = 0
  broken = false
  while RPi::GPIO.low? @echo_pin do
    if (watchdog1 += 1) > 50000
      broken = true
      break
    end
  end
  start = Time.now
  return 0.0 if broken

  while RPi::GPIO.high? @echo_pin do
    if (watchdog2 += 1) > 50000
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

auto_mode = false

bogus_count = 0
loop do
  if auto_mode
    distance = measure_average
    puts "Distance : #{sprintf("%.1f", distance)}"
    if distance < 0.0
      stop
      puts "\tbogus distance reading #{bogus_count}"
      bogus_count += 1
      case bogus_count
      when 1..3
        puts "\ttrying again in half-a-second"
        sleep(0.5)
      when 4..5
        puts "\tbacking up a bit"
        sleep(0.5)
        reverse(duration: 0.2)
        stop
      when 4..5
        puts "\tturning"
        sleep(0.5)
        rotate_right(0.1)
        stop
      else
        puts "\tnot sure what to do. Foward, I guess."
        sleep(0.5)
        forward(0.1)
        stop
      end
    elsif distance < MIN_DISTANCE
      puts "\tobstacle in path"
      puts "\treversing"
      stop
      sleep(0.5)
      reverse(duration: 0.2)
      stop
      sleep(0.5)
      rotate_left(duration: 0.1)
      next
    else
      bogus_count = 0
      puts "\tmoving forward"
      forward_forever
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
      forward(duration: 0.5)
    when 'W'
      forward(duration: 1)
    when 's'
      reverse(duration: 0.5)
    when 'S'
      reverse(duration: 1)
    when 'a'
      rotate_left(duration: 0.1)
    when 'A'
      rotate_left(duration: 0.25)
    when 'd'
      rotate_right(duration: 0.1)
    when 'D'
      rotate_right(duration: 0.25)
    when 'G'
      auto_mode = true
    when 'r'
      puts "Range: #{measure_average}"
    when '-'
      @default_speed -= 1 if @default_speed > 1
      puts "Default speed lowered to #{@default_speed}."
    when '+'
      @default_speed += 1 if @default_speed < 100
      puts "Default speed raised to #{@default_speed}."
    else
      puts "unknown command '#{cmd}'"
    end
  end
end

stop

puts "bye!"

