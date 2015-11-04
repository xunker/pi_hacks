#!/usr/bin/env ruby

require 'io/console'
require 'rpi_gpio'
require 'hitimes'

include Math

RPi::GPIO.set_numbering :bcm

PWM_DUTY_CYCLE = 50.0
PWM_FREQ = 50.0

RPi::GPIO.set_numbering :bcm

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

  return 0.0 if broken

  elapsed = Hitimes::Interval.measure do
    while RPi::GPIO.high? @echo_pin do
      if (watchdog2 += 1) > 50000
        broken = true
        break
      end
    end
  end

  return 0.0 if broken

  distance = (elapsed * 34300.0)/2
  return distance
end

def measure_average
  measurements = 25.times.map{|i|
    measure.tap{|m| puts "Measurement #{i}: #{m}"; sleep(0.01)}
  }
  # distance = (measurements.inject(:+) / measurements.length.to_f).round(2)
  distance = interquartile_mean(measurements)
  puts "Measurement Avg: #{distance}"
  return distance
end


def interquartile_mean(ary)
  a = ary.sort
  l = ary.size
  quart = (l.to_f / 4).floor
  t = a[quart..-(quart + 1)]
  t.inject{ |s, e| s + e }.to_f / t.size
end

def log_distance(degrees)
  File.open("./mapper.log", "a") do |file|
    x = measure_average

    radians = (degrees * Math::PI / 180.0).round(2)
    puts "Degree: #{degrees}, Radian: #{radians}"


    delta_x, delta_y = polar_to_cartesian(x, radians)

    scad = "[#{delta_x}, #{delta_y}],"
    file.puts scad
    puts scad
  end
end

def polar_to_cartesian(magnitude, radians)
  [(magnitude*cos(radians)).round(2), (magnitude*sin(radians)).round(2)]
end


def rotate_right(duration: 0.5)
  puts 'rotate right'
  stop
  set_rotate_right
  go

  sleep(duration)

  stop
end

def stop
  stop_left_motor
  stop_right_motor
end

def stop_left_motor
  @left_pwm.stop
end

def stop_right_motor
  @right_pwm.stop
end

def set_rotate_right
  RPi::GPIO.set_high @left_direction_pin
  RPi::GPIO.set_high @right_direction_pin
end

def go
  start_left_motor
  start_right_motor
end

def start_left_motor
  @left_pwm.start(PWM_DUTY_CYCLE)
end

def start_right_motor
  @right_pwm.start(PWM_DUTY_CYCLE)
end

def log_and_move
  log_distance(@current_degree)

  rotate_right(duration: 0.05)
  inc_degrees
end

def inc_degrees
  @current_degree += 1.0
  if @current_degree > 360.0
    @current_degree = 0.0
  end
end

@current_degree = 0.0

File.open("./mapper.log", "w") do |file|
  file.puts "polygon(points=["
end

loop do
  print 'command> '
  cmd = STDIN.getch.strip
  case cmd
  when 'x'
    File.open("./mapper.log", "a") do |file|
      file.puts "]);"
    end
    break
  when 'm'
    log_distance(@current_degree)
    inc_degrees
  when 'l'
    log_and_move
  when 'L'
    30.times do |i|
    # while @current_degree < 10
      log_and_move
      sleep(1.0)
    end
  else
    puts "unknown command '#{cmd}'"
  end
end

puts "bye!"

