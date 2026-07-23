/**
 * Lightweight app-store seed for slim Docker images (no ts-node / full app-store graph).
 * Upserts the allowlisted apps so Google Calendar / Meet can be enabled at runtime.
 */
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const apps = [
  {
    slug: "google-calendar",
    dirName: "googlecalendar",
    categories: ["calendar"],
    type: "google_calendar",
    enabled: true,
  },
  {
    slug: "google-meet",
    dirName: "googlevideo",
    categories: ["conferencing"],
    type: "google_video",
    enabled: true,
  },
  {
    slug: "daily-video",
    dirName: "dailyvideo",
    categories: ["conferencing"],
    type: "daily_video",
    enabled: Boolean(process.env.DAILY_API_KEY),
  },
  {
    slug: "stripe",
    dirName: "stripepayment",
    categories: ["payment"],
    type: "stripe_payment",
    enabled: false,
  },
  {
    slug: "apple-calendar",
    dirName: "applecalendar",
    categories: ["calendar"],
    type: "apple_calendar",
    enabled: true,
  },
  {
    slug: "ics-feed",
    dirName: "ics-feedcalendar",
    categories: ["calendar"],
    type: "ics-feed_calendar",
    enabled: true,
  },
  {
    slug: "caldav-calendar",
    dirName: "caldavcalendar",
    categories: ["calendar"],
    type: "caldav_calendar",
    enabled: true,
  },
];

async function upsertApp(app) {
  const found = await prisma.app.findFirst({
    where: {
      OR: [{ slug: app.slug }, { dirName: app.dirName }],
    },
  });

  const data = {
    slug: app.slug,
    dirName: app.dirName,
    categories: app.categories,
    enabled: app.enabled,
  };

  if (!found) {
    await prisma.app.create({ data });
    console.log(`📲 Created app: '${app.slug}'`);
  } else {
    await prisma.app.update({ where: { slug: found.slug }, data });
    console.log(`📲 Updated app: '${app.slug}'`);
  }

  await prisma.credential.updateMany({
    where: { type: app.type },
    data: { appId: app.slug },
  });
}

async function main() {
  for (const app of apps) {
    try {
      await upsertApp(app);
    } catch (e) {
      console.log(`Could not upsert app: ${app.slug}. Error:`, e);
    }
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
