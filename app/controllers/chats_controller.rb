class ChatsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Load all chats for the current user, most recent first
    @chats = current_user.chats.joins(:document_attachment).order(created_at: :desc)
  end

  def show
    # Find a specific chat belonging to the current user
    @chat = current_user.chats.find(params[:id])
  end

  def new
    # Initialize a new chat instance for the upload form
    @chat = Chat.new
  end

  # Save the chat, trigger AI analysis if a document was attached, then redirect to results
  def create
    @chat = current_user.chats.build(chat_params)
    @chat.checklist_item_id ||= ChecklistItem.first.id

    if @chat.save
      if @chat.document.attached?
        ai_data = @chat.analyze_document
        @chat.update(
          title: ai_data["title"],
          amount: ai_data["amount"],
          deadline: ai_data["deadline"],
          urgency: ai_data["urgency"],
          document_type: ai_data["document_type"],
          advice: ai_data["advice"]
        )
      end
      redirect_to chat_path(@chat), notice: "Document scanned and analyzed!"
    else
      render :new, status: :unprocessable_entity
    end
  end
  def destroy
  @chat = current_user.chats.find(params[:id])
  @chat.destroy
  redirect_to chats_path, notice: "Document deleted."
  end

  private

  def chat_params
    # Strong parameters permitting the checklist item ID and the attached document (PDF or image files)
    params.require(:chat).permit(:checklist_item_id, :document)
  end
end
