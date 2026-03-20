# Cria automaticamente o inbox "Chat Interno" para cada conta ao iniciar o servidor.
# Isso garante que o recurso de chat interno entre agentes funcione sem configuração manual.
Rails.application.config.after_initialize do
  Thread.new do
    sleep 30 # aguarda o banco de dados estar pronto
    begin
      Account.find_each do |account|
        begin
          next if account.inboxes.exists?(name: 'Chat Interno')

          channel = Channel::Api.create!(account: account, webhook_url: '')
          account.inboxes.create!(name: 'Chat Interno', channel: channel)
          Rails.logger.info "[InternalChat] Inbox 'Chat Interno' criado para account #{account.id}"
        rescue => e
          Rails.logger.warn "[InternalChat] Skipped account #{account.id}: #{e.message}"
        end
      end
    rescue => e
      Rails.logger.warn "[InternalChat] Setup adiado (DB pode não estar pronto): #{e.message}"
    end
  end
end
