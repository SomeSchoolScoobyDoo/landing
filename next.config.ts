import type { NextConfig } from "next";
const nextConfig: NextConfig = {
  poweredByHeader: false,
  reactStrictMode: true,
  devIndicators: false,
  outputFileTracingIncludes: {
    "/certificates/*": ["./assets/certificates/*.b64"],
  },
};
export default nextConfig;
