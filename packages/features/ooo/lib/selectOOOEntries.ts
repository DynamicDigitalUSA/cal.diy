/** Prisma select for OOO entries used by webhooks and tRPC (kept out of app-store for slim builds). */
export const selectOOOEntries = {
  id: true,
  start: true,
  end: true,
  createdAt: true,
  updatedAt: true,
  notes: true,
  showNotePublicly: true,
  reason: {
    select: {
      reason: true,
      emoji: true,
    },
  },
  reasonId: true,
  user: {
    select: {
      id: true,
      name: true,
      email: true,
      timeZone: true,
    },
  },
  toUser: {
    select: {
      id: true,
      name: true,
      email: true,
      timeZone: true,
    },
  },
  uuid: true,
} as const;
