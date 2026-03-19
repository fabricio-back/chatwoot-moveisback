# v1.12 — NotificationListener: conversation_created notifica apenas administradores.
# Agentes comuns só são notificados via conversation_assignment quando a conversa
# for atribuída a eles, evitando acesso a conversas não atribuídas pelo sino 🔔.
class NotificationListener < BaseListener
  def conversation_created(event)
    conversation = extract_conversation_and_account(event, 'conversation')[0]
    account = conversation.account

    account.users
           .joins(:account_users)
           .where(account_users: { account_id: account.id, role: :administrator })
           .each do |user|
      NotificationBuilder.new(
        notification_type: 'conversation_creation',
        user: user,
        conversation: conversation
      ).perform
    end
  end
end

NotificationListener.prepend_mod_with('NotificationListener')
