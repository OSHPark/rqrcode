module RQRCode
  module Export
    module Gerber
      attr_accessor :positive, :precision, :pixel_width, :x_origin, :y_origin, :quiet_zone_size, :mirrored
      ##
      # Returns a string of the QR code as
      # characters writen with ANSI background set.
      # 
      # Options: 
      # light: Foreground ("\033[47m")
      # dark: Background ANSI code. ("\033[47m")
      # fill_character: The written character. ('  ')
      # quiet_zone_size: (4)
      #
      def flash(x,y)
        top_y = (@module_count + (@quiet_zone_size *2 )) * @pixel_width
        y = top_y - (y * @pixel_width)
        if @mirrored then
          right_x = (@module_count + (@quiet_zone_size*2)) * @pixel_width 
          x = right_x - (x * @pixel_width)
        else
          x = x * @pixel_width
        end
        
        x += (@x_origin)
        y += (@y_origin)

        y = (y * @p_mult).to_i
        x = (x * @p_mult).to_i
        return "G01X#{x}Y#{y}D03*\n"
      end

      def is_light(x,y)
        ! is_dark(x,y)
      end

      def as_gerber(options={})
        options = {
          precision: 6,
          pixel_width: 0.010, # inches
          x_origin: 0.000, # inches
          y_origin: 0.000, # inches
          quiet_zone_size: 1,
          mirrored: false
        }.merge(options)
        @x_origin = options.fetch(:x_origin)
        @y_origin = options.fetch(:y_origin)
        @precision = options.fetch(:precision)
        @pixel_width = options.fetch(:pixel_width)
        @quiet_zone_size = options.fetch(:quiet_zone_size)
        @mirrored = options.fetch(:mirrored)

        @p_mult = 10**options[:precision]

        output=<<-EOF
G04 This is an RQRCode Generated gerber file.*
G04 --End of header info--*
%MOIN*%
%FSLAX3#{options[:precision]}Y3#{options[:precision]}*%
%IPPOS*%
%ADD10R,#{options[:pixel_width]}X#{options[:pixel_width]}*%
G04 --Start main section--*
G54D10*
        EOF

        quiet_zone_size = options.fetch(:quiet_zone_size)

        width = quiet_zone_size + @module_count + quiet_zone_size

        quiet_zone_size.times do |r|
          width.times do |c|
            output << flash(c,r) ## Top Quiet Zone
            output << flash(r,c) ## Left Quiet Zone
            output << flash(r+quiet_zone_size+@module_count,c)
            output << flash(c,r+quiet_zone_size+@module_count)
          end
        end


        @modules.each_index do |r|
          @modules[r].each_index do |c|
            if is_light(r, c)
              output << flash(quiet_zone_size+c,quiet_zone_size+r)
            end
          end
        end

        output << "M02*\n"

        return output
      end
    end
  end
end

RQRCode::QRCode.send :include, RQRCode::Export::Gerber
