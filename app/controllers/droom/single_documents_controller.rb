module Droom
  class SingleDocumentsController < Droom::DroomController

    respond_to :html, :json, :ics, :js
    load_and_authorize_resource

    def serve_pdf
      pdf = SingleDocument.find(params[:id])
      file = open(pdf.file.url) # use `URI.open` if needed
    
      send_data file.read,
                filename: pdf.file.filename.to_s,
                type: 'application/pdf',
                disposition: 'inline'
    end    

  end
end
