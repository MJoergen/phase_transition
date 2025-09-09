#!/usr/bin/env ruby

require 'gosu'

class PhaseTransition < Gosu::Window

  # Parameters that can be tweeked
  CELL_SIZE = 8
  WIDTH     = 160
  HEIGHT    = 100
  FONT_SIZE = 24
  SPEED     = 100

  # Called once at startup
  def initialize
    super(WIDTH*CELL_SIZE, HEIGHT*CELL_SIZE + FONT_SIZE, false)
    self.caption = "Phase Transition"

    @font = Gosu::Font.new(self, Gosu.default_font_name, FONT_SIZE)
    @col_white       = Gosu::Color.new(0xffffffff)
    @col_black       = Gosu::Color.new(0xff000000)
    @col_dark_red    = Gosu::Color.new(0xffff0000)
    @col_red         = Gosu::Color.new(0xffff8080)
    @col_light_red   = Gosu::Color.new(0xffffc0c0)
    @col_dark_green  = Gosu::Color.new(0xff00ff00)
    @col_green       = Gosu::Color.new(0xff80ff80)
    @col_light_green = Gosu::Color.new(0xffc0ffc0)
    @col_dark_blue   = Gosu::Color.new(0xff0000ff)
    @col_blue        = Gosu::Color.new(0xff8080ff)
    @col_light_blue  = Gosu::Color.new(0xffc0c0ff)
    @col_faded_red   = Gosu::Color.new(0x80ff0000)
    @col_faded_green = Gosu::Color.new(0x8000ff00)
    @col_faded_blue  = Gosu::Color.new(0x800000ff)
    @point_img       = Gosu::Image.new("Point.png", :tileable => true)

    # Initial equilibrium parameters
    # The range for temperature is [0, 1]
    # The range for chemical potential is [-3, -1]
    @temperature = 0.3
    @chem_pot    = -2.5

    @paused = 1
    @graph  = 1

    reset
  end

  # When user presses 'R'
  def reset
    @cells = []
    (0..HEIGHT-1).each{|row|
      @cells.push([0]*WIDTH)
    }
    @energy_list = []
    @number_list = []
    p @energy_list
  end

  # Calculate contribution to energy from this site
  def energy(occupied, neighbors)
    -occupied*neighbors
  end

  # Calculate contribution to number from this site
  def number(occupied, neighbors)
    occupied
  end

  # When user presses 'S'
  def step
    # Choose a random site
    x = rand(WIDTH)
    y = rand(HEIGHT)

    # Is this site occupied?
    occupied     = @cells[y][x]

    # Number of living neighbors
    neighbors = @cells[(y+1) % HEIGHT][x] +
      @cells[(y-1) % HEIGHT][x] +
      @cells[y][(x+1) % WIDTH] +
      @cells[y][(x-1) % WIDTH]

    # Calculate current and new values of energy and number
    e_current = energy(occupied,   neighbors)
    e_new     = energy(1-occupied, neighbors)
    n_current = number(occupied,   neighbors)
    n_new     = number(1-occupied, neighbors)

    # Calculate current and new values of Hamiltonian
    h_current = e_current - @chem_pot * n_current
    h_new     = e_new     - @chem_pot * n_new

    q = Math.exp((h_current - h_new)/@temperature)

    prob_swap = q/(1+q)

    if rand < prob_swap then
      @cells[y][x] = 1 - @cells[y][x]
    end
  end

  # Called once a frame
  def update
    if @paused == 0
      (1..SPEED).each {|iter|
        step
      }
    end
  end

  def draw_graph(x1, y1, x2, y2, ary, num_points, color)

    ## x1, y1 is the upper left corner of the graph                                 example: x1, y1 = 10, 10
    ## x2, y2 is the lower right corner of the graph                                example: x2, y2 = 500, 400
    ## ary is the full array of data                                                example: [9, 10, 8, 6, 10, 11, 9, 12]
    ## num_points is the amount of points that should be displayed on the graph     example: 5
    ## the graph displays the values from the last 'num_points' elements of 'ary'

    if ary.empty? == true
      return false
    end

    point_color = color
    point_scale = 1.0
    line_color = color
    graph_z = 2
    ## Generate a new array that contains only the last 'num_points' elements.
    ary_new = ary.drop([ary.length-num_points, 0].max)
    min_value = ary_new.min
    max_value = ary_new.max

    self.draw_line(x1, y1,   color, x1, y2, color, graph_z)
    self.draw_line(x2, y1,   color, x2, y2, color, graph_z)
    self.draw_line(x1-5, y1, color, x2, y1, color, graph_z)
    self.draw_line(x1-5, y2, color, x2, y2, color, graph_z)
    @font.draw_text("#{max_value}", x1, y1-18, graph_z, 1.0, 1.0, color)
    @font.draw_text("#{min_value}", x1, y2+3,  graph_z, 1.0, 1.0, color)

    for i in 0..ary_new.length-1
      px1 = x1 + i*(x2-x1)/num_points
      py1 = y2 - (ary_new[i]-min_value)*(y2-y1)/(max_value-min_value)
      @point_img.draw_rot(px1, py1, graph_z, 0, 0.5, 0.5, point_scale, point_scale, point_color)
      if i < ary_new.length-1
        px2 = x1 + (i+1)*(x2-x1)/num_points
        py2 = y2 - (ary_new[i+1]-min_value)*(y2-y1)/(max_value-min_value)
        self.draw_line(px1, py1, line_color, px2, py2, line_color, graph_z)
      end
    end
  end

  # Called once a frame
  def draw
    cnt_energy = 0.0
    cnt_number = 0.0

    (0..HEIGHT-1).each {|row|
      (0..WIDTH-1).each {|col|
        draw_rect(col*CELL_SIZE, row*CELL_SIZE, CELL_SIZE, CELL_SIZE, @col_white)
        if @cells[row][col] > 0 then
          cnt_number += 1
          draw_rect(col*CELL_SIZE+1, row*CELL_SIZE+1, CELL_SIZE-2, CELL_SIZE-2, @col_blue)
          if @cells[(row-1)%HEIGHT][col] > 0 then
            draw_rect(col*CELL_SIZE+3*CELL_SIZE/8, row*CELL_SIZE-CELL_SIZE/2, CELL_SIZE/4, CELL_SIZE-2, @col_red)
            cnt_energy += 1
          end
          if @cells[row][(col-1)%WIDTH] > 0 then
            draw_rect(col*CELL_SIZE-CELL_SIZE/2, row*CELL_SIZE+3*CELL_SIZE/8, CELL_SIZE-2, CELL_SIZE/4, @col_red)
            cnt_energy += 1
          end

        else
          draw_rect(col*CELL_SIZE+1, row*CELL_SIZE+1, CELL_SIZE-2, CELL_SIZE-2, @col_light_blue)
        end
      }
    }
    hamiltonian = cnt_energy-@chem_pot*cnt_number

    @energy_list.push(cnt_energy)
    @number_list.push(cnt_number)

    if @graph > 0 then
      draw_graph(0, 0,                  WIDTH*CELL_SIZE, HEIGHT*CELL_SIZE/2, @number_list, WIDTH*CELL_SIZE, @col_faded_red)
      draw_graph(0, HEIGHT*CELL_SIZE/2, WIDTH*CELL_SIZE, HEIGHT*CELL_SIZE,   @energy_list, WIDTH*CELL_SIZE, @col_faded_green)
    end

    @font.draw_text(sprintf("N=%6.4f", cnt_number/HEIGHT/WIDTH),  100, HEIGHT*CELL_SIZE, 0)
    @font.draw_text(sprintf("E=%6.4f", cnt_energy/HEIGHT/WIDTH),  200, HEIGHT*CELL_SIZE, 0)
    @font.draw_text(sprintf("H=%6.4f", hamiltonian/HEIGHT/WIDTH), 300, HEIGHT*CELL_SIZE, 0)
    @font.draw_text(sprintf("M=%4.2f", @chem_pot) ,               400, HEIGHT*CELL_SIZE, 0)
    @font.draw_text(sprintf("T=%4.2f", @temperature),             500, HEIGHT*CELL_SIZE, 0)
  end

  def needs_cursor?
    true
  end

  def button_down(id)
    if id == Gosu::KbEscape
      close
    end
    if id == Gosu::KbP
      @paused = 1 - @paused
    end
    if id == Gosu::KbR
      reset
    end
    if id == Gosu::KbS
      step
    end
    if id == Gosu::KbA
      @temperature -= 0.1
      @temperature = [@temperature, 0.1].max
    end
    if id == Gosu::KbD
      @temperature += 0.1
      @temperature = [@temperature, 1.0].min
    end
    if id == Gosu::KbW
      @chem_pot += 0.1
      @chem_pot = [@chem_pot, -1.0].min
    end
    if id == Gosu::KbX
      @chem_pot -= 0.1
      @chem_pot = [@chem_pot, -3.0].max
    end
    if id == Gosu::KbG
      @graph = 1 - @graph
    end
  end
end

window = PhaseTransition.new
window.show

