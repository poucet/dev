/**
 * The working system, loaded into every pi session.
 *
 * Installed once (`pi install <path to dev>`), this puts the system's rules in
 * front of every agent, in every repo, with nothing linked into the repo, and
 * orders them with the repo's own rules so the more specific always comes later:
 *
 *   1. whatever pi loads from its agent directory (`~/.pi/agent/AGENTS.md`);
 *   2. `default-agent.md` beside this file: who the agent is unless a project or
 *      persona says otherwise;
 *   3. `AGENTS.md` beside this file: the system itself;
 *   4. for each directory from the filesystem root down to the working
 *      directory: its `AGENTS.md` (pi loads these itself), then its local
 *      `.pi/AGENTS.md` (added here: rules kept out of the repo, untracked by
 *      `.pi/`'s own `.gitignore`).
 *
 * Every file appears once, by real path, wherever it was first loaded from.
 *
 * It also gives a repo's `.pi/` its `.gitignore` of `*` when it has none: that
 * directory holds local state (sessions, the agent tree, reports, drafts, local
 * rules) and never belongs in history.
 *
 * The roles and skills ship through the package manifest (`pi.personas`,
 * `pi.skills` in package.json), not from here.
 */

import { existsSync, mkdirSync, readFileSync, realpathSync, writeFileSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { type ExtensionAPI, getAgentDir } from "@earendil-works/pi-coding-agent";

type ContextFile = { path: string; content: string };

const HERE = dirname(fileURLToPath(import.meta.url));

/** The system's own files, in the order an agent should read them. */
const SYSTEM_FILES = [join(HERE, "default-agent.md"), join(HERE, "AGENTS.md")];

/** A directory's local rules, beside its `AGENTS.md`. */
const LOCAL_RULES = join(".pi", "AGENTS.md");

function realpath(p: string): string {
	try {
		return realpathSync(p);
	} catch {
		return resolve(p);
	}
}

function read(path: string): ContextFile | undefined {
	try {
		return { path, content: readFileSync(path, "utf-8") };
	} catch {
		return undefined;
	}
}

/** `cwd` and its ancestors, outermost first. */
export function ancestry(cwd: string): string[] {
	const dirs: string[] = [];
	let current = resolve(cwd);
	for (;;) {
		dirs.unshift(current);
		const parent = dirname(current);
		if (parent === current) return dirs;
		current = parent;
	}
}

/** The nearest directory at or above `cwd` holding `.jj` or `.git`. */
export function projectRoot(cwd: string): string | undefined {
	for (const dir of [...ancestry(cwd)].reverse()) {
		if (existsSync(join(dir, ".jj")) || existsSync(join(dir, ".git"))) return dir;
	}
	return undefined;
}

/** The nearest ancestor of `p` (or `p` itself) named `.pi`, if any. */
export function enclosingPiDir(p: string): string | undefined {
	return [...ancestry(p)].reverse().find((dir) => basename(dir) === ".pi");
}

/** Give `<dir>/.pi` a `.gitignore` of `*` if it has none. Best effort. */
export function ensureLocalStateIgnored(dir: string): void {
	const pi = join(dir, ".pi");
	const ignore = join(pi, ".gitignore");
	if (existsSync(ignore)) return;
	try {
		mkdirSync(pi, { recursive: true });
		writeFileSync(ignore, "*\n", { flag: "wx" });
	} catch {
		// An unwritable repo is not a reason to fail a session.
	}
}

/**
 * The context files for a session in `cwd`, given what pi loaded itself
 * (`loaded`: its agent directory's file first, then each ancestor's
 * `AGENTS.md`, outermost first). Pure apart from reading files.
 */
export function orderContextFiles(
	loaded: readonly ContextFile[],
	cwd: string,
	agentDir: string,
): ContextFile[] {
	const seen = new Set<string>();
	const out: ContextFile[] = [];
	const add = (file: ContextFile | undefined) => {
		if (!file) return;
		const key = realpath(file.path);
		if (seen.has(key)) return;
		seen.add(key);
		out.push(file);
	};

	// 1. the agent directory's own file
	const agentKey = realpath(agentDir);
	const fromAgentDir = loaded.filter((f) => realpath(dirname(f.path)) === agentKey);
	fromAgentDir.forEach(add);
	// 2–3. the system
	SYSTEM_FILES.forEach((path) => add(read(path)));
	// 4. each directory, outermost first: its AGENTS.md, then its .pi/AGENTS.md
	const byDir = new Map<string, ContextFile[]>();
	for (const file of loaded) {
		const dir = realpath(dirname(file.path));
		byDir.set(dir, [...(byDir.get(dir) ?? []), file]);
	}
	for (const dir of ancestry(cwd)) {
		(byDir.get(realpath(dir)) ?? []).forEach(add);
		byDir.delete(realpath(dir));
		const local = join(dir, LOCAL_RULES);
		if (existsSync(local)) add(read(local));
	}
	// Anything pi loaded from elsewhere keeps its place at the end.
	for (const files of byDir.values()) files.forEach(add);
	return out;
}

export default function simplyDev(pi: ExtensionAPI): void {
	pi.on("session_start", (_event, ctx) => {
		const project = projectRoot(ctx.cwd);
		if (project) ensureLocalStateIgnored(project);
		// A relative `sessionDir` (".pi/sessions") resolves from wherever pi was
		// started, which can be below the repo root: that `.pi/` needs ignoring too.
		const sessionDir = ctx.sessionManager?.getSessionDir?.();
		const owner = sessionDir ? enclosingPiDir(sessionDir) : undefined;
		if (owner) ensureLocalStateIgnored(dirname(owner));
	});

	pi.on("before_agent_start", (event, ctx) => {
		const options = event.systemPromptOptions;
		const ordered = orderContextFiles(options.contextFiles ?? [], options.cwd ?? ctx.cwd, getAgentDir());
		options.contextFiles = ordered;
	});
}
