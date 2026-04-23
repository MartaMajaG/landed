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

      # 3. TRIGGER MATCHER LOGIC
      # Pass the extracted text to our Fat Model to find the correct Knowledge Base ruleset
      combined_text = "#{ai_data['title']} #{ai_data['document_type']} #{ai_data['advice']}"
      match_result = DocumentType.match(combined_text)

      # 4. Mapping to document storage Logic
      @document.update(
        title:         ai_data["title"],
        amount:        ai_data["amount"],
        deadline:      ai_data["deadline"],
        urgency:       ai_data["urgency"],
        document_type: ai_data["document_type"], # Keep raw string for fallback
        advice:        ai_data["advice"],
        document_type_id: match_result[:document_type]&.id # Link to Knowledge Base
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
    
    # Reconstruct the match hash for the view
    if @document.document_type
      @match = {
        matched_type: @document.document_type,
        confidence_score: 1.0, # Pre-matched
        target_logic: @document.document_type.master_data["logic"] || {}
      }
    else
      @match = { matched_type: nil, confidence_score: 0, target_logic: {} }
    end
  end

  # Stateless Q&A chat using Hotwire Turbo Streams
  def ask
    @document = Document.find(params[:id])
    @question = params[:question]
    
    begin
      client = Anthropic::Client.new
      prompt = "Document Content: #{@document.advice}\n\nQuestion: #{@question}"
      
      response = client.messages.create(
        parameters: {
          model: "claude-3-5-sonnet-20240620",
          max_tokens: 500,
          system: "You are a helpful assistant answering questions about a specific document. Keep answers brief.",
          messages: [{ role: "user", content: prompt }]
        }
      )
      @answer = response.dig("content", 0, "text")
    rescue => e
      Rails.logger.error "Anthropic Chat Failed: #{e.message}"
      @answer = "Sorry, I couldn't process that request right now."
    end
    
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  # 'Strong Params' for standard security!
  # We only allow the :file to be passed through from the frontend!!
  def document_params
    params.require(:document).permit(:file)
  end
end