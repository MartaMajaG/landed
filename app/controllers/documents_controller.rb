class DocumentsController < ApplicationController
  # This action handles the incoming 'POST' request from upload form
  def create
    # 1. We build the document linked to the current user.
    # 'document_params' (at the bottom) ensures we only accept the file.
    @document = current_user.documents.build(document_params)

    if @document.save
      # 2. TRIGGER AI Logic
      # Now that the file is saved in ActiveStorage, we call model method.
      # It goes to claude, gets the JSON, and returns a hash.
      ai_data = @document.extract_ai_data

      # 3. Mapping to document storage Logic
      # We update the document with the extracted data. 
      # FYI: 'document_type' is the key needed for bureaucracy seeds!
      @document.update(
        title:         ai_data["title"],
        amount:        ai_data["amount"],
        deadline:      ai_data["deadline"],
        urgency:       ai_data["urgency"],
        document_type: ai_data["document_type"],
        advice:        ai_data["advice"]
      )

      # 4. SUCCESS: Move to the 'Show' page 
      redirect_to document_path(@document), notice: "Document scanned and analyzed!"
    else
      # 5. FAILURE: If the file wasn't valid, stay on the upload page
      render :new, status: :unprocessable_entity
    end
  end

  # This allows user to see the result of a specific scan
  def show
    @document = Document.find(params[:id])
  end

  private

  # 'Strong Params' for standard security!
  # We only allow the :file to be passed through from the frontend!!
  def document_params
    params.require(:document).permit(:file)
  end
end