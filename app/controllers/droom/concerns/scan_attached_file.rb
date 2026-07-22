module Droom::Concerns::ScanAttachedFile
  extend ActiveSupport::Concern

  # Files larger than this threshold will be scanned in background
  LARGE_FILE_THRESHOLD = 25.megabytes

  class_methods do
    def clamav_scan_file_for(param_paths, options = {})
      fallback = options.delete(:fallback) || :root_path
      paths = Array(param_paths)

      before_action(options) do
        scan_failed = false
        
        paths.each do |param_path|
          uploaded = param_path.to_s.split('.').inject(params) { |h, key| h[key] if h }
          next unless uploaded.is_a?(ActionDispatch::Http::UploadedFile)

          # Skip synchronous scan for large files — they'll be scanned asynchronously
          # via ScanDocumentFileJob after the record is saved
          if uploaded.size > LARGE_FILE_THRESHOLD
            Rails.logger.info "⏳ Large file upload (#{(uploaded.size / 1.megabyte.to_f).round(1)}MB), deferring virus scan to background job"
            next
          end

          result = ClamavServices.scan_file(uploaded.tempfile.path )
          @object_name = param_path.to_s.split('.').first

          case result[:status]
          when :infected
            Rails.logger.error("[:infected] File scanning failed: #{result[:message]}")
            flash[:alert] = I18n.t("validations.file.malware_detected")
            scan_failed = true
            break
          when :error
            Rails.logger.error("[:error] File scanning error: #{result[:message]}")
            flash[:alert] = I18n.t("validations.file.upload_fail")
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

  def scan_attachment(name, file_path)
    result = ClamavServices.scan_file(file_path)
    case result[:status]
    when :infected
      Rails.logger.error("[:infected] File scanning failed: #{result[:message]}")
      return I18n.t("validations.file.malware_detected")
    when :error
      Rails.logger.error("[:error] File scanning error: #{result[:message]}")
      return I18n.t("validations.file.upload_fail")
    end
  end
end