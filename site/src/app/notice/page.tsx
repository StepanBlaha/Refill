import Legal from "@/components/Legal";
import Content from "@/components/NoticeContent";
import { pageMeta } from "@/lib/site";

export const metadata = pageMeta({
  title: "Third-Party Notices | Refill",
  description: "Trademarks, non-affiliation and undocumented-API disclaimer for Refill.",
  path: "notice/",
});

export default function Page() {
  return (
    <Legal>
      <Content />
    </Legal>
  );
}
