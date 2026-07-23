import type { NextApiRequest, NextApiResponse } from "next";

/** Payment app removed from slim builds — webhook is a no-op. */
export default function handler(_req: NextApiRequest, res: NextApiResponse) {
  res.status(404).json({ message: "App not available in this build" });
}
