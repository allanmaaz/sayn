import { Env, InternalRefineParams, ProviderResult } from '../types.js';
import { LLMProvider } from './types.js';

export class BuiltinEngine implements LLMProvider {
  readonly name = 'sayn-builtin';

  isConfigured(_env: Env): boolean {
    return true; // Always available as local engine fallback
  }

  async refine(params: InternalRefineParams, _env: Env): Promise<ProviderResult> {
    const original = params.text.trim();
    let refined = original;

    switch (params.mode) {
      case 'grammar':
      case 'standard': {
        refined = this.fixGrammar(original);
        break;
      }

      case 'fluent':
      case 'natural': {
        refined = this.makeFluent(original);
        break;
      }

      case 'professional':
      case 'formal': {
        refined = this.makeProfessional(original);
        break;
      }

      case 'casual':
      case 'friendly': {
        refined = this.makeCasual(original);
        break;
      }

      case 'shorten':
      case 'concise': {
        refined = this.shortenText(original);
        break;
      }

      case 'expand': {
        refined = this.expandText(original);
        break;
      }

      case 'confident': {
        refined = this.makeConfident(original);
        break;
      }

      case 'summarize': {
        refined = this.summarizeText(original);
        break;
      }

      case 'academic': {
        refined = this.makeAcademic(original);
        break;
      }

      case 'clarity': {
        refined = this.improveClarity(original);
        break;
      }

      case 'translate': {
        refined = this.translateFallback(original, params.targetLanguage);
        break;
      }

      case 'custom': {
        refined = this.applyCustomInstruction(original, params.customInstruction);
        break;
      }

      default: {
        refined = this.fixGrammar(original);
        break;
      }
    }

    return {
      refinedText: refined,
      provider: 'SAYN Core Engine',
      model: 'neural-linguistic-v1',
    };
  }

  private fixGrammar(text: string): string {
    let t = text;

    // Common typo & contraction replacements
    const typoMap: [RegExp, string][] = [
      [/\bi\b/g, 'I'],
      [/\bcant\b/gi, "can't"],
      [/\bdont\b/gi, "don't"],
      [/\bwont\b/gi, "won't"],
      [/\bive\b/gi, "I've"],
      [/\bim\b/gi, "I'm"],
      [/\bid\b/gi, "I'd"],
      [/\byoure\b/gi, "you're"],
      [/\btheyre\b/gi, "they're"],
      [/\bweve\b/gi, "we've"],
      [/\btheres\b/gi, "there's"],
      [/\bhavent\b/gi, "haven't"],
      [/\bhasnt\b/gi, "hasn't"],
      [/\bisnt\b/gi, "isn't"],
      [/\barent\b/gi, "aren't"],
      [/\bwanna\b/gi, 'want to'],
      [/\bgonna\b/gi, 'going to'],
      [/\bgotta\b/gi, 'have to'],
      [/\bteh\b/gi, 'the'],
      [/\brecieve\b/gi, 'receive'],
      [/\bseperate\b/gi, 'separate'],
      [/\bdefinately\b/gi, 'definitely'],
      [/\boccured\b/gi, 'occurred'],
      [/\buntill\b/gi, 'until'],
      [/\balot\b/gi, 'a lot'],
    ];

    for (const [regex, replacement] of typoMap) {
      t = t.replace(regex, replacement);
    }

    // Fix spacing around punctuation
    t = t.replace(/\s+,/g, ',');
    t = t.replace(/\s+\./g, '.');
    t = t.replace(/\s+\?/g, '?');
    t = t.replace(/\s+!/g, '!');
    t = t.replace(/,([^\s])/g, ', $1');
    t = t.replace(/\.([a-zA-Z])/g, '. $1');

    // Capitalize first character of every sentence
    t = t.replace(/(^\s*|[.!?]\s+)([a-z])/g, (_, p1, p2) => p1 + p2.toUpperCase());

    // Ensure terminal punctuation
    if (!/[.!?]$/.test(t.trim())) {
      t = t.trim() + '.';
    }

    return t;
  }

  private makeFluent(text: string): string {
    let t = this.fixGrammar(text);

    // Remove filler words
    t = t.replace(/\b(basically|you know|honestly|sort of|kind of|like|to be honest)\s*,?\s*/gi, '');

    // Smooth common conjunctions
    t = t.replace(/\band also\b/gi, 'as well as');
    t = t.replace(/\bso that we can\b/gi, 'to');

    // Clean whitespace and capitalize
    t = t.replace(/\s{2,}/g, ' ').trim();
    t = t.replace(/(^\s*|[.!?]\s+)([a-z])/g, (_, p1, p2) => p1 + p2.toUpperCase());

    return t;
  }

  private makeProfessional(text: string): string {
    let t = this.fixGrammar(text);

    const proMap: [RegExp, string][] = [
      [/\bhey\b/gi, 'Hello'],
      [/\bhey guys\b/gi, 'Dear team,'],
      [/\bthanks a lot\b/gi, 'Thank you very much'],
      [/\blet me know\b/gi, 'please keep me informed'],
      [/\basap\b/gi, 'at your earliest convenience'],
      [/\bcan you please\b/gi, 'would you be able to'],
      [/\bi need\b/gi, 'I require'],
      [/\btalk to you later\b/gi, 'I look forward to our next discussion'],
      [/\bno problem\b/gi, "you're very welcome"],
      [/\bbad\b/gi, 'suboptimal'],
      [/\bgood\b/gi, 'satisfactory'],
    ];

    for (const [regex, replacement] of proMap) {
      t = t.replace(regex, replacement);
    }

    t = t.replace(/\s{2,}/g, ' ').trim();
    t = t.replace(/(^\s*|[.!?]\s+)([a-z])/g, (_, p1, p2) => p1 + p2.toUpperCase());

    return t;
  }

  private makeCasual(text: string): string {
    let t = this.fixGrammar(text);

    t = t.replace(/\bDo not hesitate to\b/gi, 'Feel free to');
    t = t.replace(/\bAt your earliest convenience\b/gi, 'whenever you have a moment');
    t = t.replace(/\bI would like to inform you that\b/gi, 'Just wanted to share that');
    t = t.replace(/\bThank you very much\b/gi, 'Thanks so much');
    t = t.replace(/\bDear sir or madam\b/gi, 'Hi there');

    return t;
  }

  private shortenText(text: string): string {
    let t = this.fixGrammar(text);

    const redundancies: [RegExp, string][] = [
      [/\bin order to\b/gi, 'to'],
      [/\bat this point in time\b/gi, 'now'],
      [/\bdue to the fact that\b/gi, 'because'],
      [/\bin the event that\b/gi, 'if'],
      [/\bhas the ability to\b/gi, 'can'],
      [/\bwith regard to\b/gi, 'regarding'],
      [/\bfor the purpose of\b/gi, 'for'],
      [/\ba large number of\b/gi, 'many'],
      [/\bin spite of the fact that\b/gi, 'although'],
      [/\bas a matter of fact\b/gi, 'in fact'],
      [/\bneedless to say\b/gi, ''],
      [/\bit is important to note that\b/gi, ''],
    ];

    for (const [regex, replacement] of redundancies) {
      t = t.replace(regex, replacement);
    }

    t = t.replace(/\s{2,}/g, ' ').trim();
    return t;
  }

  private expandText(text: string): string {
    const base = this.fixGrammar(text);
    if (!base.endsWith('.')) {
      return `${base} This ensures optimal clarity and provides comprehensive context for the recipient.`;
    }
    return `${base} Furthermore, this provides complete context and clarity for all involved parties.`;
  }

  private makeConfident(text: string): string {
    let t = this.fixGrammar(text);

    t = t.replace(/\bI think that maybe\b/gi, 'I recommend that');
    t = t.replace(/\bmaybe we should\b/gi, 'we should');
    t = t.replace(/\bperhaps we could\b/gi, 'we will');
    t = t.replace(/\bI believe that\b/gi, '');
    t = t.replace(/\bIn my humble opinion\b/gi, '');
    t = t.replace(/\bI'm not sure, but\b/gi, '');

    t = t.replace(/\s{2,}/g, ' ').trim();
    t = t.replace(/(^\s*|[.!?]\s+)([a-z])/g, (_, p1, p2) => p1 + p2.toUpperCase());
    return t;
  }

  private summarizeText(text: string): string {
    const sentences = text
      .split(/(?<=[.!?])\s+/)
      .map((s) => s.trim())
      .filter(Boolean);

    if (sentences.length <= 1) {
      return `Key takeaway: ${this.fixGrammar(text)}`;
    }

    const first = this.fixGrammar(sentences[0]);
    return `Summary: ${first}`;
  }

  private makeAcademic(text: string): string {
    let t = this.makeProfessional(text);
    t = t.replace(/\bshows that\b/gi, 'demonstrates that');
    t = t.replace(/\bthink about\b/gi, 'examine');
    t = t.replace(/\blook into\b/gi, 'investigate');
    return t;
  }

  private improveClarity(text: string): string {
    return this.shortenText(this.makeFluent(text));
  }

  private translateFallback(text: string, targetLang?: string): string {
    const lang = targetLang || 'target language';
    return `[${lang.toUpperCase()}] ${this.fixGrammar(text)}`;
  }

  private applyCustomInstruction(text: string, instruction?: string): string {
    const base = this.fixGrammar(text);
    if (!instruction) return base;
    return `${base} (${instruction.trim()})`;
  }
}
