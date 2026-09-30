import Legal from "@/components/Legal";
import Content from "@/components/PrivacyContent";
import { pageMeta } from "@/lib/site";

export const metadata = pageMeta({
  title: "Privacy | Refill",
  description: "Refill's privacy policy: no data collection by the developer, everything stays on your Mac.",
  path: "privacy/",
});

export default function Page() {
  return (
    <Legal>
      <Content />
    </Legal>
  );
}
