import Link from "next/link";
import Drip from "@/components/Drip";
import Legal from "@/components/Legal";
import { pageMeta } from "@/lib/site";

export const metadata = pageMeta({
  title: "Page not found | Refill",
  description: "This page does not exist. Head back to Refill.",
  path: "404.html",
  noindex: true,
});

export default function NotFound() {
  return (
    <Legal>
      <Drip mood="asleep" pct={0} size={96} title="Drip, the Refill mascot, asleep with an empty tank" />
      <h1>Page not found</h1>
      <p>This tank is empty. The page you were looking for does not exist.</p>
      <p>
        <Link href="/">Go to the Refill home page</Link>
      </p>
    </Legal>
  );
}
