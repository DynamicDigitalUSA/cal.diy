import { prisma } from "@calcom/prisma";
import type { Prisma } from "@calcom/prisma/client";

import { TRPCError } from "@trpc/server";

import type { TrpcSessionUser } from "../../../types";
import type { TUpdateAppCredentialsInputSchema } from "./updateAppCredentials.schema";

export type UpdateAppCredentialsOptions = {
  ctx: {
    user: NonNullable<TrpcSessionUser>;
  };
  input: TUpdateAppCredentialsInputSchema;
};

type CredentialValidator = (args: {
  input: TUpdateAppCredentialsInputSchema;
}) => Promise<TUpdateAppCredentialsInputSchema["key"]>;

/** Optional per-app validators — string specifier so missing apps do not break slim builds. */
const loadValidator = async (appId: string): Promise<CredentialValidator | null> => {
  if (appId !== "paypal") return null;
  try {
    // Non-literal specifier: TypeScript must not require the module at compile time
    const specifier = "@calcom/app-store/paypal/lib/updateAppCredentials.validator";
    const mod = (await import(specifier)) as { default: CredentialValidator };
    return mod.default;
  } catch {
    return null;
  }
};

export const handleCustomValidations = async ({
  input,
  appId,
}: UpdateAppCredentialsOptions & { appId: string }) => {
  const { key } = input;
  const validator = await loadValidator(appId);
  // If no validator is found, return the key as is
  if (!validator) return key;
  try {
    return await validator({ input });
  } catch (error) {
    throw new TRPCError({
      code: "BAD_REQUEST",
      message: error instanceof Error ? error.message : "Validation failed",
    });
  }
};

export const updateAppCredentialsHandler = async ({ ctx, input }: UpdateAppCredentialsOptions) => {
  const { user } = ctx;

  // Find user credential
  const credential = await prisma.credential.findFirst({
    where: {
      id: input.credentialId,
      userId: user.id,
    },
  });
  // Check if credential exists
  if (!credential) {
    throw new TRPCError({
      code: "BAD_REQUEST",
      message: `Could not find credential ${input.credentialId}`,
    });
  }

  const validatedKeys = await handleCustomValidations({ ctx, input, appId: credential.appId || "" });

  const updated = await prisma.credential.update({
    where: {
      id: credential.id,
    },
    data: {
      key: {
        ...(credential.key as Prisma.JsonObject),
        ...(validatedKeys as Prisma.JsonObject),
      },
    },
  });

  return !!updated;
};
