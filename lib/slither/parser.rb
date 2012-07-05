class Slither
  class Parser
        
    def initialize(definition, file_io)
      @definition = definition
      @file = file_io
      # This may be used in the future for non-linear or repeating sections
      @mode = :linear
    end
    
    def parse()
      parsed = {}

      @file.each_line do |line|
        line.chomp! if line
        @definition.sections.each do |section|
          if section.match(line)
            validate_length(line, section)
            parsed = fill_content(line, section, parsed)
          end
        end
      end

      @definition.sections.each do |section|
        raise(Slither::RequiredSectionNotFoundError, "Required section '#{section.name}' was not found.") unless parsed[section.name] || section.optional
      end
      parsed
    end
    
    def parse_by_bytes
      parsed = {}
      
      all_section_lengths = @definition.sections.map{|sec| sec.length }
      byte_length = all_section_lengths.max
      all_section_lengths.each { |bytes| raise(Slither::SectionsNotSameLengthError,
          "All sections must have the same number of bytes for parse by bytes") if bytes != byte_length }
      
      while record = @file.read(byte_length)
        raise(Slither::LineWrongSizeError, "newline character was not at the end of byte group (was #{@file.getc})") unless remove_newlines! && record.length == byte_length
    
        record.force_encoding @file.external_encoding
        
        @definition.sections.each do |section|
          if section.match(record)
            parsed = fill_content(record, section, parsed)
          end
        end
      end
      
      @definition.sections.each do |section|
        raise(Slither::RequiredSectionNotFoundError, "Required section '#{section.name}' was not found.") unless parsed[section.name] || section.optional
      end
      parsed
    end
    
    private
    
      def fill_content(line, section, parsed)
        parsed[section.name] = [] unless parsed[section.name]
        parsed[section.name] << section.parse(line)
        parsed
      end
      
      def validate_length(line, section)
        raise Slither::LineWrongSizeError, "Line wrong size: (#{line.length} when it should be #{section.length})" if line.length != section.length
      end
      
      def remove_newlines!
        return true if @file.eof?
        b = @file.getbyte
        if newline?(b)
          remove_newlines!
          return true
        else
          @file.ungetbyte b
          return false
        end
      end
      
      def newline?(char_code)
        # \n or LF -> 10
        # \r or CR -> 13
        [10, 13].any?{|code| char_code == code}
      end
      
  end
end