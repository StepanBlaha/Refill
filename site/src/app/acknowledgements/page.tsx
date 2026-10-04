import Legal from "@/components/Legal";
import NoticeContent from "@/components/NoticeContent";
import { pageMeta } from "@/lib/site";

export const metadata = pageMeta({
  title: "Acknowledgements | Refill",
  description: "Third-party notices and acknowledgements for Refill.",
  path: "acknowledgements/",
});

export default function Page() {
  return (
    <Legal crumb={{ name: "Acknowledgements", path: "acknowledgements/" }}>
      <NoticeContent
        title="Acknowledgements"
        lede="Third-party notices for Refill: trademarks, the undocumented usage endpoints, and what the MIT license does not cover. The same text is in the repository at legal/NOTICE.md."
      />
    </Legal>
  );
}
