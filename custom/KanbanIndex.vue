<script setup>
/* global axios */
import { ref, computed, onMounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';

const { accountId } = useAccount();
const router = useRouter();
const store = useStore();

const labels = useMapGetter('labels/getLabels');

// columns: { [labelTitle]: { conversations, loading, color, title } }
const columns = ref({});
const isRefreshing = ref(false);
const dragState = ref({ convId: null, fromLabel: null, conv: null });
const dropTarget = ref('');

// Initialize column structure from label list
const syncColumns = labelList => {
  const updated = {};
  labelList.forEach(label => {
    updated[label.title] = {
      title: label.title,
      color: label.color || '#6b7280',
      conversations: columns.value[label.title]?.conversations || [],
      loading: false,
    };
  });
  columns.value = updated;
};

watch(
  labels,
  newLabels => {
    if (newLabels.length > 0) {
      syncColumns(newLabels);
      fetchAll();
    }
  },
  { immediate: true }
);

onMounted(() => {
  store.dispatch('labels/get');
});

// Fetch conversations for a single label column
const fetchColumn = async labelTitle => {
  const col = columns.value[labelTitle];
  if (!col) return;
  col.loading = true;
  try {
    const response = await axios.get(
      `/api/v1/accounts/${accountId.value}/conversations`,
      {
        params: {
          labels: labelTitle,
          status: 'open',
          assignee_type: 'all',
          page: 1,
        },
      }
    );
    col.conversations = response.data?.data?.payload || [];
  } catch {
    col.conversations = [];
  } finally {
    col.loading = false;
  }
};

const fetchAll = async () => {
  isRefreshing.value = true;
  await Promise.all(Object.keys(columns.value).map(fetchColumn));
  isRefreshing.value = false;
};

// Drag-and-drop handlers
const onDragStart = (event, conv, fromLabel) => {
  dragState.value = { convId: conv.id, fromLabel, conv };
  event.dataTransfer.effectAllowed = 'move';
};

const onDragOver = (event, labelTitle) => {
  event.preventDefault();
  event.dataTransfer.dropEffect = 'move';
  dropTarget.value = labelTitle;
};

const onDragLeave = event => {
  // Only clear if leaving the column entirely (not entering a child)
  if (!event.currentTarget.contains(event.relatedTarget)) {
    dropTarget.value = '';
  }
};

const onDrop = async (event, targetLabel) => {
  event.preventDefault();
  dropTarget.value = '';

  const { convId, fromLabel, conv } = dragState.value;
  dragState.value = { convId: null, fromLabel: null, conv: null };

  if (!convId || fromLabel === targetLabel) return;

  // Compute new label list: remove source label, add target label
  const currentLabels = Array.isArray(conv.labels) ? [...conv.labels] : [];
  const newLabels = currentLabels.filter(l => l !== fromLabel);
  if (!newLabels.includes(targetLabel)) newLabels.push(targetLabel);

  // Optimistic UI update
  const fromCol = columns.value[fromLabel];
  const toCol = columns.value[targetLabel];
  if (fromCol) {
    fromCol.conversations = fromCol.conversations.filter(c => c.id !== convId);
  }
  const updatedConv = { ...conv, labels: newLabels };
  if (toCol) toCol.conversations.unshift(updatedConv);

  // Persist via API
  try {
    await axios.post(
      `/api/v1/accounts/${accountId.value}/conversations/${convId}/labels`,
      { labels: newLabels }
    );
  } catch {
    // Revert optimistic update on failure
    if (fromCol) fromCol.conversations.unshift(conv);
    if (toCol) {
      toCol.conversations = toCol.conversations.filter(c => c.id !== convId);
    }
  }
};

// Navigate to the conversation detail
const openConversation = convId => {
  router.push(`/app/accounts/${accountId.value}/conversations/${convId}`);
};

// Human-readable relative time (Portuguese)
const relativeTime = ts => {
  if (!ts) return '';
  const diff = Math.floor((Date.now() / 1000 - ts) / 60); // minutes ago
  if (diff < 1) return 'agora';
  if (diff < 60) return `${diff}min`;
  const h = Math.floor(diff / 60);
  if (h < 24) return `${h}h`;
  return `${Math.floor(h / 24)}d`;
};

const labelColumns = computed(() => Object.values(columns.value));
</script>

<template>
  <section class="flex flex-col w-full h-full bg-n-surface-1 overflow-hidden">
    <!-- Header -->
    <div
      class="flex items-center justify-between px-6 py-4 border-b border-n-weak flex-shrink-0"
    >
      <div class="flex items-center gap-3">
        <span class="i-lucide-kanban size-5 text-n-slate-11" />
        <h1 class="text-base font-semibold text-n-slate-12">
          Kanban de Etiquetas
        </h1>
      </div>
      <button
        class="flex items-center gap-1.5 px-3 py-1.5 text-sm rounded-lg border border-n-weak bg-n-solid-2 hover:bg-n-solid-3 text-n-slate-11 disabled:opacity-50 transition-colors"
        :disabled="isRefreshing"
        @click="fetchAll"
      >
        <span
          class="i-lucide-refresh-cw size-3.5"
          :class="isRefreshing ? 'animate-spin' : ''"
        />
        Atualizar
      </button>
    </div>

    <!-- Empty state: no labels configured -->
    <div
      v-if="labelColumns.length === 0"
      class="flex flex-col items-center justify-center flex-1 gap-3 text-n-slate-10"
    >
      <span class="i-lucide-tag size-10 opacity-30" />
      <p class="text-sm">
        Nenhuma etiqueta cadastrada.
      </p>
      <p class="text-xs text-n-slate-9">
        Crie etiquetas em Configurações → Etiquetas.
      </p>
    </div>

    <!-- Kanban board -->
    <div
      v-else
      class="flex flex-row gap-3 p-4 overflow-x-auto flex-1 min-h-0 items-start"
    >
      <div
        v-for="col in labelColumns"
        :key="col.title"
        class="flex flex-col rounded-xl border min-w-[272px] max-w-[272px] h-full transition-all bg-n-solid-2"
        :class="
          dropTarget === col.title
            ? 'border-[var(--color-woot-500)] ring-2 ring-[var(--color-woot-500)] ring-opacity-30'
            : 'border-n-weak'
        "
        @dragover="onDragOver($event, col.title)"
        @dragleave="onDragLeave"
        @drop="onDrop($event, col.title)"
      >
        <!-- Column header -->
        <div
          class="flex items-center justify-between px-3 py-3 border-b border-n-weak flex-shrink-0"
        >
          <div class="flex items-center gap-2 min-w-0">
            <span
              class="size-2.5 rounded-sm flex-shrink-0"
              :style="{ backgroundColor: col.color }"
            />
            <span
              class="text-sm font-medium text-n-slate-12 truncate"
              :title="col.title"
            >
              {{ col.title }}
            </span>
          </div>
          <span
            class="ml-2 flex-shrink-0 min-w-[20px] text-center px-1.5 py-0.5 rounded-full bg-n-solid-3 text-xs text-n-slate-10 font-medium"
          >
            {{ col.loading ? '…' : col.conversations.length }}
          </span>
        </div>

        <!-- Cards area -->
        <div class="flex flex-col gap-2 p-2 overflow-y-auto flex-1 min-h-0">
          <!-- Loading -->
          <div
            v-if="col.loading"
            class="flex items-center justify-center py-10"
          >
            <span
              class="i-lucide-loader-circle size-5 text-n-slate-9 animate-spin"
            />
          </div>

          <!-- Empty -->
          <div
            v-else-if="col.conversations.length === 0"
            class="flex flex-col items-center justify-center py-10 gap-2 text-n-slate-9"
          >
            <span class="i-lucide-inbox size-6 opacity-30" />
            <p class="text-xs">Sem conversas</p>
          </div>

          <!-- Conversation cards -->
          <template v-else>
            <div
              v-for="conv in col.conversations"
              :key="conv.id"
              class="rounded-lg bg-n-solid-1 border border-n-weak p-3 cursor-grab active:cursor-grabbing hover:border-n-strong hover:shadow-sm transition-all select-none"
              draggable="true"
              @dragstart="onDragStart($event, conv, col.title)"
              @click.stop="openConversation(conv.id)"
            >
              <!-- Contact name + time -->
              <div class="flex items-start justify-between gap-2 mb-1.5">
                <span
                  class="text-sm font-medium text-n-slate-12 leading-tight truncate"
                >
                  {{ conv.meta?.sender?.name || 'Contato' }}
                </span>
                <span class="text-xs text-n-slate-9 flex-shrink-0 mt-0.5">
                  {{ relativeTime(conv.timestamp || conv.created_at) }}
                </span>
              </div>

              <!-- Conversation ID -->
              <p class="text-xs text-n-slate-9 mb-2">
                #{{ conv.id }}
              </p>

              <!-- Labels chips -->
              <div
                v-if="conv.labels && conv.labels.length > 0"
                class="flex flex-wrap gap-1 mb-2"
              >
                <span
                  v-for="lbl in conv.labels"
                  :key="lbl"
                  class="px-1.5 py-0.5 rounded text-[10px] font-medium"
                  :style="{
                    backgroundColor:
                      labels.find(l => l.title === lbl)?.color + '22' ||
                      '#6b728022',
                    color:
                      labels.find(l => l.title === lbl)?.color || '#6b7280',
                  }"
                >
                  {{ lbl }}
                </span>
              </div>

              <!-- Assignee -->
              <div
                v-if="conv.meta?.assignee"
                class="flex items-center gap-1.5 mt-1"
              >
                <span class="i-lucide-circle-user size-3 text-n-slate-9" />
                <span class="text-xs text-n-slate-9 truncate">
                  {{ conv.meta.assignee.name }}
                </span>
              </div>
            </div>
          </template>
        </div>
      </div>
    </div>
  </section>
</template>
