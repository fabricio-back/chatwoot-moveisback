// v1.11 — applyRoleFilter: agentes só veem conversas onde são assignee ou participantes
export const applyRoleFilter = (conversation, role, permissions, currentUserId) => {
  if (role === 'administrator') return true;

  const assigneeId = conversation.meta?.assignee?.id;
  const isParticipant = conversation.meta?.is_participant === true;

  return assigneeId === currentUserId || isParticipant;
};

export const sortComparator = (a, b, sortKey) => {
  if (sortKey === 'created_at') {
    return new Date(b.created_at) - new Date(a.created_at);
  }
  if (sortKey === 'last_activity_at') {
    const aTime = a.last_activity_at || a.created_at;
    const bTime = b.last_activity_at || b.created_at;
    return new Date(bTime) - new Date(aTime);
  }
  // Default: sort by last_activity_at desc
  const aTime = a.last_activity_at || a.created_at;
  const bTime = b.last_activity_at || b.created_at;
  return new Date(bTime) - new Date(aTime);
};

export const applyPageFilters = (conversation, filters) => {
  const { assignee_type: assigneeType, status } = filters;

  if (status && conversation.status !== status) return false;

  if (assigneeType === 'me') {
    return true; // getMineChats handles this separately
  }
  if (assigneeType === 'unassigned') {
    return !conversation.meta?.assignee;
  }
  if (assigneeType === 'assigned') {
    return !!conversation.meta?.assignee;
  }

  return true;
};
