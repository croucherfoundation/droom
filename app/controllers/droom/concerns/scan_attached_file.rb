module Droom::Concerns::ScanAttachedFile
  extend ActiveSupport::Concern

  class_methods do
    def clamav_scan_file_for(param_paths, options = {})
      fallback = options.delete(:fallback) || :root_path
      paths = Array(param_paths)

      before_action(options) do
        scan_failed = false
        
        paths.each do |param_path|
          uploaded = param_path.to_s.split('.').inject(params) { |h, key| h[key] if h }
          next unless uploaded.is_a?(ActionDispatch::Http::UploadedFile)
          result = ClamavServices.scan_file(uploaded.tempfile.path )
          @object_name = param_path.to_s.split('.').first

          case result[:status]
          when :infected
            flash[:alert] = "The uploaded file contains malware: #{result[:message]}"
            scan_failed = true
            break
          when :error
            flash[:alert] = "An error occurred while scanning the uploaded file: #{result[:message]}"
            scan_failed = true
            break
          end
        end
        
        if scan_failed
          if request.xhr? # AJAX request
            Rails.logger.debug "ClamAV scan failed for AJAX request"
            render json: { message: flash[:alert] }, status: 422
          elsif @object_name == 'document' # Special case for document uploads
             Rails.logger.debug "ClamAV scan failed for document upload"
            # Render JSON response for document uploads
            render json: "#{flash[:alert]}", status: 422
          else # Regular HTTP request
            redirect_back(fallback_location: send(fallback))
          end
          false # This halts the before_action chain
        end
      end
    end
  end
end