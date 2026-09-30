import Link from "next/link";
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
      <h1>Page not found</h1>
      <p>This tank is empty. The page you were looking for does not exist.</p>
      <p>
        <Link href="/">Go to the Refill home page</Link>
      </p>
    </Legal>
  );
}
