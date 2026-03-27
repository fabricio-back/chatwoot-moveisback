<script setup>
/* global axios */
import { ref, watch, onUnmounted, nextTick, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

const emit = defineEmits(['close']);

const { accountId } = useAccount();
const currentUser = useMapGetter('getCurrentUser');

const agents = ref([]);
const selectedAgent = ref(null);
const messages = ref([]);
const newMessage = ref('');
const inboxId = ref(null);
const conversationId = ref(null);
const loading = ref(false);
const sending = ref(false);
const errorMsg = ref('');
const messagesEl = ref(null);
let pollTimer = null;

const INBOX_NAME = 'Chat Interno';

// ---------- utils ----------

const pairKey = (idA, idB) =>
  [Math.min(idA, idB), Math.max(idA, idB)].join('-');

const dmContactEmail = (pair) => `internal-dm-${pair}@system.local`;

const agentInitial = (name) => (name || '?')[0].toUpperCase();

const agentColor = (id) => {
  const colors = [
    '#aa0101', '#b45309', '#047857', '#1d4ed8', '#6d28d9', '#be185d',
    '#0891b2', '#65a30d', '#dc2626', '#7c3aed',
  ];
  return colors[Math.abs(id) % colors.length];
};

const formatTime = (ts) => {
  const d = new Date(ts * 1000);
  return d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
};

const isMyMessage = (msg) => msg.sender?.id === currentUser.value?.id;

// ---------- API ----------

const fetchAgents = async () => {
  try {
    const res = await axios.get(`/api/v1/accounts/${accountId.value}/agents`);
    agents.value = (res.data || []).filter((a) => a.id !== currentUser.value?.id);
  } catch (e) {
    errorMsg.value = 'Não foi possível carregar os agentes.';
  }
};

const findOrCreateInbox = async () => {
  const res = await axios.get(`/api/v1/accounts/${accountId.value}/inboxes`);
  const list = res.data?.payload || [];
  let inbox = list.find((i) => i.name === INBOX_NAME);
  if (!inbox) {
    if (currentUser.value?.role !== 'administrator') {
      throw new Error(
        `O inbox "${INBOX_NAME}" ainda não foi criado. Solicite a um administrador que acesse o Chat Interno uma vez para criá-lo automaticamente.`
      );
    }
    const created = await axios.post(
      `/api/v1/accounts/${accountId.value}/inboxes`,
      { name: INBOX_NAME, channel: { type: 'api', webhook_url: '' } }
    );
    inbox = created.data;
  }
  inboxId.value = inbox.id;
};

const findOrCreateContact = async (pair, nameA, nameB) => {
  const email = dmContactEmail(pair);
  try {
    const search = await axios.get(
      `/api/v1/accounts/${accountId.value}/contacts/search`,
      { params: { q: email, include_contacts: true } }
    );
    // Chatwoot v4 returns { payload: { contacts: [...], meta: {} } }
    // older versions return { payload: [...] } — handle both
    const rawPayload = search.data?.payload;
    const contacts = Array.isArray(rawPayload)
      ? rawPayload
      : (rawPayload?.contacts || []);
    if (contacts.length > 0 && contacts[0]?.id) return contacts[0].id;
  } catch {
    /* continue to create */
  }
  const created = await axios.post(
    `/api/v1/accounts/${accountId.value}/contacts`,
    { name: `DM: ${nameA} & ${nameB}`, email, account_id: accountId.value }
  );
  return created.data?.id;
};

const findOrCreateConversation = async (contactId) => {
  if (!contactId) throw new Error('Não foi possível criar ou localizar o contato da conversa.');
  const res = await axios.get(
    `/api/v1/accounts/${accountId.value}/contacts/${contactId}/conversations`
  );
  const convs = res.data?.payload || [];
  const existing = convs.find((c) => c.inbox_id === inboxId.value);
  if (existing) return existing.id;

  const created = await axios.post(
    `/api/v1/accounts/${accountId.value}/conversations`,
    {
      inbox_id: inboxId.value,
      contact_id: contactId,
      assignee_id: currentUser.value?.id,
    }
  );
  // Add both agents as participants so both receive notifications
  const convId = created.data.id;
  await axios.post(
    `/api/v1/accounts/${accountId.value}/conversations/${convId}/participants`,
    { user_ids: [currentUser.value?.id, selectedAgent.value?.id].filter(Boolean) }
  ).catch(() => {});
  return convId;
};

const fetchMessages = async () => {
  if (!conversationId.value) return;
  try {
    const res = await axios.get(
      `/api/v1/accounts/${accountId.value}/conversations/${conversationId.value}/messages`
    );
    const all = res.data?.payload || [];
    const filtered = all
      .filter((m) => m.message_type !== 2 && m.message_type !== 3) // exclude activity & template
      .sort((a, b) => a.created_at - b.created_at);
    const prevCount = messages.value.length;
    messages.value = filtered;
    if (filtered.length !== prevCount) scrollBottom();
  } catch {
    /* ignore poll errors */
  }
};

const sendMessage = async () => {
  const text = newMessage.value.trim();
  if (!text || !conversationId.value || sending.value) return;
  newMessage.value = '';
  sending.value = true;
  try {
    await axios.post(
      `/api/v1/accounts/${accountId.value}/conversations/${conversationId.value}/messages`,
      { content: text, message_type: 'outgoing', private: true }
    );
    await fetchMessages();
  } catch {
    newMessage.value = text; // restore on failure
  } finally {
    sending.value = false;
  }
};

// ---------- open chat ----------

const openChat = async (agent) => {
  selectedAgent.value = agent;
  loading.value = true;
  errorMsg.value = '';
  messages.value = [];
  conversationId.value = null;
  stopPoll();
  try {
    if (!inboxId.value) await findOrCreateInbox();
    const myId = currentUser.value?.id;
    const pair = pairKey(myId, agent.id);
    const contactId = await findOrCreateContact(pair, currentUser.value?.name || 'Eu', agent.name);
    conversationId.value = await findOrCreateConversation(contactId);
    await fetchMessages();
    startPoll();
  } catch (e) {
    errorMsg.value = e.message || 'Erro ao abrir conversa.';
  } finally {
    loading.value = false;
  }
};

const backToList = () => {
  stopPoll();
  selectedAgent.value = null;
  messages.value = [];
  conversationId.value = null;
  errorMsg.value = '';
};

// ---------- poll ----------

const startPoll = () => {
  stopPoll();
  pollTimer = setInterval(fetchMessages, 3000);
};

const stopPoll = () => {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
};

// ---------- scroll ----------

const scrollBottom = () => {
  nextTick(() => {
    if (messagesEl.value)
      messagesEl.value.scrollTop = messagesEl.value.scrollHeight;
  });
};

// ---------- lifecycle ----------

watch(
  () => currentUser.value?.id,
  (id) => {
    if (id) {
      fetchAgents();
      findOrCreateInbox().catch(() => {});
    }
  },
  { immediate: true }
);

onUnmounted(stopPoll);
</script>

<template>
  <!-- Header -->
  <div class="flex items-center gap-2 px-3 py-2 border-b border-n-weak flex-shrink-0">
    <button
      v-if="selectedAgent"
      class="flex items-center justify-center size-7 rounded-lg hover:bg-n-alpha-2 transition-colors text-n-slate-11"
      @click="backToList"
    >
      <span class="i-lucide-arrow-left size-4" />
    </button>
    <span class="flex-grow font-semibold text-sm text-n-slate-12 truncate">
      {{ selectedAgent ? selectedAgent.name : 'Chat Interno' }}
    </span>
    <button
      class="flex items-center justify-center size-7 rounded-lg hover:bg-n-alpha-2 transition-colors text-n-slate-11"
      @click="emit('close')"
    >
      <span class="i-lucide-x size-4" />
    </button>
  </div>

  <!-- Error banner -->
  <div
    v-if="errorMsg"
    class="mx-3 mt-2 p-2 rounded-lg bg-red-50 dark:bg-red-950 border border-red-200 dark:border-red-800 text-red-700 dark:text-red-300 text-xs flex gap-2"
  >
    <span class="i-lucide-alert-circle size-4 flex-shrink-0 mt-0.5" />
    <span>{{ errorMsg }}</span>
  </div>

  <!-- Agent list -->
  <div v-if="!selectedAgent" class="flex-1 overflow-y-auto">
    <div v-if="!agents.length" class="flex items-center justify-center h-24 text-n-slate-10 text-sm gap-2">
      <span class="i-lucide-loader-circle size-4 animate-spin" />
      Carregando agentes...
    </div>
    <button
      v-for="agent in agents"
      :key="agent.id"
      class="flex items-center gap-3 w-full px-3 py-2.5 hover:bg-n-alpha-2 transition-colors text-left min-w-0"
      @click="openChat(agent)"
    >
      <div
        class="flex items-center justify-center size-8 rounded-full flex-shrink-0 text-white font-semibold text-xs"
        :style="{ backgroundColor: agentColor(agent.id) }"
      >
        {{ agentInitial(agent.name) }}
      </div>
      <div class="flex-1 min-w-0">
        <div class="text-sm font-medium text-n-slate-12 truncate">{{ agent.name }}</div>
        <div class="text-xs text-n-slate-10">
          {{ agent.role === 'administrator' ? 'Administrador' : 'Agente' }}
        </div>
      </div>
      <span class="i-lucide-chevron-right size-4 text-n-slate-9 flex-shrink-0" />
    </button>
  </div>

  <!-- Chat view -->
  <template v-else-if="selectedAgent && !errorMsg">
    <!-- Loading spinner -->
    <div v-if="loading" class="flex items-center justify-center flex-1 text-n-slate-10 gap-2 text-sm">
      <span class="i-lucide-loader-circle size-5 animate-spin" />
      Abrindo conversa...
    </div>

    <!-- Messages -->
    <div v-else ref="messagesEl" class="flex-1 overflow-y-auto p-3 flex flex-col gap-2">
      <div
        v-for="msg in messages"
        :key="msg.id"
        class="flex"
        :class="isMyMessage(msg) ? 'justify-end' : 'justify-start'"
      >
        <div
          class="max-w-[80%] rounded-2xl px-3 py-2 text-sm break-words"
          :class="
            isMyMessage(msg)
              ? 'bg-n-brand text-white rounded-br-sm'
              : 'bg-n-alpha-2 text-n-slate-12 rounded-bl-sm'
          "
        >
          <p class="leading-snug whitespace-pre-wrap">{{ msg.content }}</p>
          <span
            class="text-[10px] block mt-1 opacity-70"
            :class="isMyMessage(msg) ? 'text-right' : 'text-left'"
          >
            {{ formatTime(msg.created_at) }}
          </span>
        </div>
      </div>
      <div
        v-if="!messages.length"
        class="flex-1 flex items-center justify-center text-n-slate-10 text-sm text-center py-8"
      >
        Nenhuma mensagem ainda.<br />Diga olá! 👋
      </div>
    </div>

    <!-- Input bar -->
    <div class="flex items-center gap-2 px-3 py-2 border-t border-n-weak flex-shrink-0">
      <input
        v-model="newMessage"
        class="flex-1 text-sm px-3 py-1.5 rounded-lg border border-n-weak bg-n-background text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:ring-1 focus:ring-n-brand min-w-0"
        placeholder="Mensagem..."
        :disabled="sending || loading"
        @keydown.enter.prevent="sendMessage"
      />
      <button
        class="flex items-center justify-center size-8 rounded-lg transition-colors flex-shrink-0"
        :class="
          newMessage.trim() && !sending
            ? 'bg-n-brand text-white hover:opacity-90'
            : 'bg-n-alpha-2 text-n-slate-9 cursor-not-allowed'
        "
        :disabled="!newMessage.trim() || sending || loading"
        @click="sendMessage"
      >
        <span class="i-lucide-send-horizontal size-4" />
      </button>
    </div>
  </template>
</template>
