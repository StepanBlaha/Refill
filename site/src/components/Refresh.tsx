"use client";

import { useRefreshOnLoad } from "@/lib/motion";

/** Renders nothing. Refreshes ScrollTrigger once fonts and images have loaded. */
export default function Refresh() {
  useRefreshOnLoad();
  return null;
}
