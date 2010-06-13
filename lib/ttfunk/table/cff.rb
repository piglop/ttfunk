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
          p [major, minor]
          p [hdr_size, off_size]
          raise NotImplementedError, "To be continued..."
        end
    end
  end
end
