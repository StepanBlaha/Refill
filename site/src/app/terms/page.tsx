import Legal from "@/components/Legal";
import Content from "@/components/TermsContent";
import { pageMeta } from "@/lib/site";

export const metadata = pageMeta({
  title: "Terms of Use | Refill",
  description:
    "Refill terms of use: provided as-is, uses undocumented endpoints, not affiliated with the AI providers it reads usage from.",
  path: "terms/",
});

export default function Page() {
  return (
    <Legal>
      <Content />
    </Legal>
  );
}
