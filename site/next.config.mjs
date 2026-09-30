const base = process.env.NEXT_PUBLIC_BASE_PATH ?? "/Refill";

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "export",
  basePath: base,
  assetPrefix: base || undefined,
  images: { unoptimized: true },
  trailingSlash: true,
};

export default nextConfig;
