import type { GetServerSidePropsContext } from "next";

/** Only apps kept in the slim Docker allowlist (plus Stripe setup). */
export const AppSetupPageMap = {
  stripe: import("../../stripepayment/pages/setup/_getServerSideProps"),
};

export const getServerSideProps = async (ctx: GetServerSidePropsContext) => {
  const { slug } = ctx.params || {};
  if (typeof slug !== "string") return { notFound: true } as const;

  if (!(slug in AppSetupPageMap)) return { props: {} };

  const page = await AppSetupPageMap[slug as keyof typeof AppSetupPageMap];

  if (!page.getServerSideProps) return { props: {} };

  const props = await page.getServerSideProps(ctx);

  return props;
};
