#!/usr/bin/env ruby

require 'sinatra'
require 'pi_piper'
require 'singleton'
require 'json'

class Sinatrobot
  include PiPiper
  include Singleton

  def initialize
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

    @led1 = PiPiper::Pin.new(pin: 7, direction: :out)
    @led1.off
    @led2 = PiPiper::Pin.new(pin: 8, direction: :out)
    @led2.off

    @sw1 = PiPiper::Pin.new(pin: 11, direction: :in, pull: :down)
    @sw2 = PiPiper::Pin.new(pin: 9, direction: :in, pull: :down)
    @oc1 = PiPiper::Pin.new(pin: 22, direction: :out)
    @oc1.off
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
      if (watchdog1 += 1) > 500
        broken = true
        break 
      end
    end
    start = Time.now
    return 0.0 if broken

    while @echo_pin.read == 1 do
      if (watchdog2 += 1) > 500
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
end

set :bind, '0.0.0.0'

def ok
  { status: :ok }.to_json
end

get '/pin_states' do
  {}.tap do |h|
    %w[left_go_pin right_go_pin left_direction_pin right_direction_pin
      trigger_pin echo_pin led1 led2 sw1 sw2 oc1].sort.each do |pin|
        h[pin] = Sinatrobot.instance.instance_variable_get("@#{pin}".to_sym).read
    end
  end.to_json
end

get '/distance' do
  { distance: Sinatrobot.instance.measure_average }.to_json
end

get '/forward' do
  Sinatrobot.instance.forward((params[:duration] || 0.5).to_f)
  ok
end

get '/reverse' do
  Sinatrobot.instance.reverse((params[:duration] || 0.5).to_f)
  ok
end

get '/rotate_left' do
  Sinatrobot.instance.rotate_left((params[:duration] || 0.5).to_f)
  ok
end

get '/rotate_right' do
  Sinatrobot.instance.rotate_right((params[:duration] || 0.5).to_f)
  ok
end

