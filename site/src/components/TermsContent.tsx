import Link from "next/link";
import s from "@/components/Legal.module.css";

export default function TermsContent() {
  return (
    <>
      <h1>Terms of Use</h1>
      <p className={s.fine}>Last updated 2026-09-30</p>

      <ol >
        <li><b>The software.</b> Refill is provided by Stepan Blaha ("we") for use on your own Mac. By using it you agree to these terms. Refill is open-source software under the <a href="https://github.com/StepanBlaha/Refill/blob/main/LICENSE">MIT License</a>. The license governs the source code; these terms cover using the app.</li>
        <li><b>Your accounts.</b> Refill uses logins that you already have, such as Claude Code. You are responsible for following each provider's terms, including any limits on automated or third-party access to their services.</li>
        <li><b>Undocumented endpoints.</b> Refill relies on endpoints and file formats that providers do not document. They may change or stop working at any time, and a provider may restrict such use. Usage numbers and reset times may be late, wrong or unavailable. Do not rely on Refill where a missed or false signal would cause harm.</li>
        <li><b>Integrations, hooks and dashboard.</b> You choose which services Refill contacts and which scripts it runs. Refill is not responsible for what your integrations, webhooks or hook scripts do. Turning on the network dashboard lets anyone on your local network see your usage.</li>
        <li><b>No warranty.</b> Refill is provided "as is", without warranty of any kind.</li>
        <li><b>Limitation of liability.</b> To the extent permitted by law, we are not liable for any indirect, incidental or consequential damages, or for loss of data or account access, arising from your use of Refill.</li>
        <li><b>Trademarks.</b> Refill is an independent app and is not affiliated with, endorsed by, or sponsored by Anthropic, OpenAI, GitHub, Cursor or Google. "Claude" is a trademark of Anthropic, PBC. See the <Link href="/notice/">notice</Link>.</li>
        <li><b>Privacy.</b> See the <Link href="/privacy/">Privacy Policy</Link>.</li>
        <li><b>Changes.</b> These terms may change with new versions. Continuing to use the app means you accept the updated terms.</li>
        <li><b>Governing law.</b> These terms are governed by the laws of the Czech Republic, without limiting any mandatory consumer rights you have where you live.</li>
      </ol>
      <p>Contact: <a href="https://github.com/StepanBlaha/Refill/issues">GitHub Issues</a></p>
    </>
  );
}
