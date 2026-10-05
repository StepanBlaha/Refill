import { phone } from "./data-phone";
import { lights } from "./data-lights";
import { sources } from "./data-sources";
import { tools } from "./data-tools";
import type { Section } from "./types";

/** Order matters: it is the order on the page and in docs/GUIDES.md. */
export const SECTIONS: Section[] = [...sources, ...phone, ...lights, ...tools];
