const base = process.env.NEXT_PUBLIC_BASE_PATH ?? "/Refill";

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "export",
  basePath: base,
  assetPrefix: base || undefined,
  images: { unoptimized: true },
  trailingSlash: true,
  // `next dev` otherwise writes AGENTS.md / CLAUDE.md into site/.
  agentRules: false,
};

export default nextConfig;
