import Hero from "@/components/Hero";
import Sources from "@/components/Sources";
import Signals from "@/components/Signals";
import Integrations from "@/components/Integrations";
import Burn from "@/components/Burn";
import PrivateSection from "@/components/PrivateSection";
import Faq from "@/components/Faq";
import Download from "@/components/Download";
import { HOME_DESC, HOME_TITLE, pageMeta } from "@/lib/site";

export const metadata = pageMeta({ title: HOME_TITLE, description: HOME_DESC, path: "" });

export default function Home() {
  return (
    <main id="top">
      <Hero />
      <Sources />
      <Signals />
      <Integrations />
      <Burn />
      <PrivateSection />
      <Faq />
      <Download />
    </main>
  );
}
