import { AUTHOR, DMG, HOME_DESC, REPO, abs } from "@/lib/site";

/** Renders one JSON-LD block. */
export default function JsonLd({ data }: { data: object }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data).replace(/</g, "\\u003c") }}
    />
  );
}

const person = { "@type": "Person", name: AUTHOR.name, url: AUTHOR.url };

export const homeLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "SoftwareApplication",
      "@id": abs("#app"),
      name: "Refill",
      description: HOME_DESC,
      url: abs(""),
      image: abs("og.png"),
      operatingSystem: "macOS 14+",
      applicationCategory: "UtilitiesApplication",
      offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
      downloadUrl: DMG,
      installUrl: DMG,
      softwareVersion: "latest",
      license: "https://opensource.org/licenses/MIT",
      author: person,
      codeRepository: REPO,
      isAccessibleForFree: true,
    },
    {
      "@type": "WebSite",
      "@id": abs("#website"),
      name: "Refill",
      url: abs(""),
      inLanguage: "en",
      publisher: { "@id": abs("#org") },
    },
    {
      "@type": "Organization",
      "@id": abs("#org"),
      name: "Refill",
      url: abs(""),
      logo: abs("icon-192.png"),
      founder: person,
      sameAs: [REPO],
    },
  ],
};

export const crumbsLd = (name: string, path: string) => ({
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  itemListElement: [
    { "@type": "ListItem", position: 1, name: "Refill", item: abs("") },
    { "@type": "ListItem", position: 2, name, item: abs(path) },
  ],
});
