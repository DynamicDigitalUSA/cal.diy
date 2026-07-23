import { DynamicComponent } from "@calcom/app-store/_components/DynamicComponent";
import dynamic from "next/dynamic";

/** Setup UIs for apps kept in the slim Docker allowlist (plus Stripe). */
export const AppSetupMap = {
  "apple-calendar": dynamic(() => import("@calcom/web/components/apps/applecalendar/Setup")),
  "caldav-calendar": dynamic(() => import("@calcom/web/components/apps/caldavcalendar/Setup")),
  "ics-feed": dynamic(() => import("@calcom/web/components/apps/ics-feedcalendar/Setup")),
  stripe: dynamic(() => import("@calcom/web/components/apps/stripepayment/Setup")),
};

export const AppSetupPage = (props: { slug: string }) => {
  return <DynamicComponent<typeof AppSetupMap> componentMap={AppSetupMap} {...props} />;
};

export default AppSetupPage;
