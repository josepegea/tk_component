module TkComponent
  class Turtle
    FULL_CIRCLE = 2 * Math::PI

    attr_accessor :canvas
    attr_accessor :current_x
    attr_accessor :current_y
    attr_accessor :color
    attr_accessor :width

    def initialize(options = {})
      @canvas = options[:canvas]
      @current_x = 0
      @current_y = 0
      @angle_unit = :radians
      @current_angle = FULL_CIRCLE / 4.0
      @turtle_down = false
      @color = options[:color] || 'black'
      @width = options[:width] || 1
    end

    def clear
      @canvas.delete('all')
    end

    def down
      @turtle_down = true
    end

    def up
      @turtle_down = false
    end

    def down?
      @turtle_down
    end

    def up?
      !down?
    end

    def current_point
      [@current_x, @current_y]
    end

    def move_to_center
      @current_x = @canvas.winfo_width / 2
      @current_y = @canvas.winfo_height / 2
    end

    def forward(length)
      new_x = @current_x + length * Math.cos(@current_angle)
      new_y = @current_y - length * Math.sin(@current_angle)
      if down?
        TkcLine.new(@canvas, [current_point, [new_x, new_y]], fill: @color, width: @width)
      end
      @current_x = new_x
      @current_y = new_y
    end

    def turn_left(angle)
      @current_angle = (@current_angle + user_angle(angle)) % FULL_CIRCLE
    end

    def turn_right(angle)
      @current_angle = (@current_angle - user_angle(angle)) % FULL_CIRCLE
    end

    def point_north
      @current_angle = FULL_CIRCLE / 4.0
    end

    def point_east
      @current_angle = 0.0
    end

    def point_south
      @current_angle = FULL_CIRCLE * 3.0 / 4.0
    end

    def point_west
      @current_angle = FULL_CIRCLE / 2.0
    end

    def degrees
      @angle_unit = :degrees
    end
    alias :deg :degrees

    def radians
      @angle_unit = :radians
    end
    alias :rad :radians

    def user_angle(angle)
      return angle if @angle_unit == :radians
      (angle % 360.0) * FULL_CIRCLE / 360.0
    end
  end
end
