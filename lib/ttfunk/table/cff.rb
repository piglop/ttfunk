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
          
          offsets = read_index_offsets
          language_names = parse_index_offsets(offsets)
          p language_names
          
          raise NotImplementedError, "To be continued..."
        end
        
        def read_index_offsets
          count, off_size = read(3, 'nc')
          raise "Unsupported offSize" if off_size != 1
          offsets = read(count + 1, "c*")
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
    end
  end
end
