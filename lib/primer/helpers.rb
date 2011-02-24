module Primer
  module Helpers
    
    module ERB
      def primer(cache_key, tag_name = :div, &block)
        if Primer.ssi and not block_given?
          return %Q{<!--# include virtual="#{cache_key}" -->}
        end
        
        result = Primer.cache.compute(cache_key) do
          block_given? ?
              primer_capture_output(&block) :
              Primer.cache.routes.evaluate(cache_key)
        end
        
        if Primer.real_time and not block_given?
          result = primer_real_time(result, tag_name, cache_key)
        end
        
        return result unless block_given?
        primer_detect_buffer.concat(result)
        nil
      end
      
    private
      
      def primer_capture_output(&block)
        return primer_capture_output_from_rails(&block) if primer_rails?
        return primer_capture_output_from_sinatra(&block) if primer_sinatra?
      end
      
      def primer_real_time(fragment, tag_name, cache_key)
        <<-HTML
        <#{ tag_name } id="#{ RealTime.dom_id(cache_key) }">
        #{ fragment }
        </#{ tag_name }>
        <script type="text/javascript">PRIMER_CHANNELS.push(#{ cache_key.inspect })</script>
        HTML
      end
      
      def primer_detect_buffer
        [@output_buffer, @_out_buf].compact.first
      end
      
      def primer_rails?
        return false unless respond_to?(:capture)
        return true if defined?(ActionView::OutputBuffer)
        String === @output_buffer
      end
      
      def primer_capture_output_from_rails(&block)
        capture(&block)
      end
      
      def primer_sinatra?
        defined?(@_out_buf)
      end
      
      def primer_capture_output_from_sinatra(&block)
        original_buffer = @_out_buf
        result = @_out_buf = ''
        block.call
        @_out_buf = original_buffer
        result.to_s
      end
    end
    
  end
end

