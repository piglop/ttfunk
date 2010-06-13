require 'ttfunk/table'

module TTFunk
  class Table
    class CFF < Table
      def for(glyph_id)
        nil
      end
      
      def tag
        "CFF "
      end

      private

        def parse!
          # Reference : http://www.adobe.com/devnet/font/pdfs/5176.CFF.pdf

          major, minor, hdr_size, off_size = read(4, 'c*')
          
          raise "Unknown CFF version: #{major}.#{minor}" if [major, minor] != [1, 0]
          raise "Invalid header" if hdr_size != 4
          
          language_offsets = read_index_offsets
          language_names = parse_index_offsets(language_offsets)
          p language_names
          
          io.pos = language_offsets.last
          
          top_dict_offsets = read_index_offsets
          
          top_dict_offsets.each_with_index do |offset, i|
            next if i == top_dict_offsets.size - 1
            
            dict = parse_dict(offset, top_dict_offsets[i + 1])
            p dict
          end
          
          
          raise NotImplementedError, "To be continued..."
        end
        
        def read_index_offsets
          count, off_size = read(3, 'nC')
          raise "Unsupported offSize" if off_size != 1
          offsets = read(count + 1, "C*")
          offsets.map { |offset| io.pos - 1 + offset }
        end
        
        def parse_index_offsets(offsets)
          data = []
          offsets.each_with_index do |offset, i|
            break if i == offsets.size - 1
            parse_from(offset) do
              size = offsets[i + 1] - offset
              data << read(size, 'a*').first
            end
          end
          data
        end
        
        def read_byte
          read(1, 'C').first
        end
        
        def decode_dict_pair
          operands = []
          operator = nil
          loop do
            b0 = read_byte
            case b0
            when 32..246
              operands << (b0 - 139)
            when 247..250
              b1 = read_byte
              operands << ((b0 - 247) * 256 + b1 + 108)
            when 251..254
              b1 = read_byte
              operands << ((b0 - 251) * 256 - b1 - 108)
            when 28
              b1, b2 = read(2, 'C*')
              operands << ((b1 << 8) | b2)
            when 29
              b1, b2, b3, b4 = read(4, 'C*')
              operands << ((b1 << 24) | (b2 << 16) | (b3 << 8) | b4)
            when 30
              real_string = ""
              done = false
              while !done
                nibbles = read_byte
                nibbles = [(nibbles & 0xF0) >> 4, nibbles & 0x0F]
                nibbles.each do |nibble|
                  case nibble
                  when 0..9
                    real_string << nibble.to_s
                  when 0xa
                    real_string << "."
                  when 0xb
                    real_string << "E"
                  when 0xc
                    real_string << "E-"
                  when 0xd
                    # reserved
                  when 0xe
                    real_string << "-"
                  when 0xf
                    done = true
                    break
                  end
                end
              end
              operands << real_string.to_f
            when 12
              operator = [12, read_byte]
              break
            when 0..21
              operator = b0
              break
            else
              raise "Invalid operande: #{b0}"
            end
          end
          [operator, operands]
        end
        
        def parse_dict(offset, end_offset)
          dict = {}
          parse_from offset do
            while io.pos < end_offset
              operator, operands = decode_dict_pair
              dict[operator] = operands
            end
          end
          dict
        end
    end
  end
end
