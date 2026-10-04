import Legal from "@/components/Legal";
import PressContent from "@/components/PressContent";
import { pageMeta } from "@/lib/site";

export const metadata = pageMeta({
  title: "Press kit | Refill",
  description:
    "Refill press kit: how to write the name, boilerplate, icon downloads, colors and facts for the macOS menu bar app.",
  path: "press/",
});

export default function Page() {
  return (
    <Legal crumb={{ name: "Press kit", path: "press/" }}>
      <PressContent />
    </Legal>
  );
}
