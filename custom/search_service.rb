# v1.13 — SearchService: aplica PermissionFilterService nas queries de conversas e mensagens.
# Agentes só encontram conversas/mensagens onde são assignee ou participantes.
class SearchService
  attr_reader :current_user, :current_account, :q, :page

  def initialize(current_user, current_account, q, page)
    @current_user = current_user
    @current_account = current_account
    @q = q
    @page = page || 1
  end

  def perform
    {
      contacts: search_contacts,
      conversations: search_conversations,
      messages: search_messages,
    }
  end

  private

  def administrator?
    AccountUser.find_by(account_id: current_account.id, user_id: current_user.id)&.administrator?
  end

  def accessible_conversations
    base = current_account.conversations
    Conversations::PermissionFilterService.new(base, current_user, current_account).perform
  end

  def accessible_conversation_ids
    @accessible_conversation_ids ||= accessible_conversations.pluck(:id)
  end

  def search_contacts
    current_account.contacts
                   .where('name ILIKE :q OR email ILIKE :q OR phone_number ILIKE :q', q: "%#{q}%")
                   .limit(10)
  end

  def search_conversations
    accessible_conversations
      .where('conversations.id::text ILIKE :q OR display_id::text ILIKE :q', q: "%#{q}%")
      .order(created_at: :desc)
      .limit(10)
  end

  def search_messages
    messages = current_account.messages
                               .where('content ILIKE ?', "%#{q}%")

    unless administrator?
      messages = messages.where(conversation_id: accessible_conversation_ids)
    end

    messages.order(created_at: :desc).limit(10)
  end
end

SearchService.prepend_mod_with('SearchService')
