/**
 * The working system, loaded into every pi session.
 *
 * Installed once (`pi install <path to dev>`), this puts the system's rules in
 * front of every agent, in every repo, with nothing linked into the repo:
 *
 *   - `default-agent.md` beside this file: who the agent is unless a project or
 *     persona says otherwise;
 *   - dev's `AGENTS.md`: the system itself;
 *   - the repo's own `AGENTS.project.md`, the nearest one at or above the
 *     working directory, so a lane's workspace inside the repo finds its repo's;
 *     at each level the root's file first, else `.pi/AGENTS.project.md` (where a
 *     repo you don't own keeps it, invisible to git).
 *
 * They are added as context files on every run, after whatever pi loaded
 * itself, and never twice: a file pi already loaded (a repo that still links
 * dev's AGENTS.md at its root, say) is skipped by its real path.
 *
 * It also gives a repo's `.pi/` its `.gitignore` of `*` when it has none: that
 * directory holds local state (sessions, the agent tree, reports, drafts) and
 * never belongs in history.
 *
 * The roles and skills ship through the package manifest (`pi.personas`,
 * `pi.skills` in package.json), not from here.
 */

import { existsSync, mkdirSync, readFileSync, realpathSync, writeFileSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HERE = dirname(fileURLToPath(import.meta.url));
const DEV = resolve(HERE, "..");

/** The system's own files, in the order an agent should read them. */
const SYSTEM_FILES = [join(HERE, "default-agent.md"), join(DEV, "AGENTS.md")];

/** Where a repo keeps its rules, in the order looked for at each level. */
const PROJECT_RULES = ["AGENTS.project.md", join(".pi", "AGENTS.project.md")];

function realpath(p: string): string {
	try {
		return realpathSync(p);
	} catch {
		return resolve(p);
	}
}

/** The nearest of `names` at or above `cwd`, earlier names first at each level. */
export function findUp(cwd: string, names: readonly string[]): string | undefined {
	let current = resolve(cwd);
	for (;;) {
		for (const name of names) {
			const candidate = join(current, name);
			if (existsSync(candidate)) return candidate;
		}
		const parent = dirname(current);
		if (parent === current) return undefined;
		current = parent;
	}
}

/** The nearest directory at or above `cwd` holding `.jj` or `.git`. */
export function projectRoot(cwd: string): string | undefined {
	let current = resolve(cwd);
	for (;;) {
		if (existsSync(join(current, ".jj")) || existsSync(join(current, ".git"))) return current;
		const parent = dirname(current);
		if (parent === current) return undefined;
		current = parent;
	}
}

/** The nearest ancestor of `p` (or `p` itself) named `.pi`, if any. */
export function enclosingPiDir(p: string): string | undefined {
	let current = resolve(p);
	for (;;) {
		if (basename(current) === ".pi") return current;
		const parent = dirname(current);
		if (parent === current) return undefined;
		current = parent;
	}
}

/** Give `<project>/.pi` a `.gitignore` of `*` if it has none. Best effort. */
export function ensureLocalStateIgnored(project: string): void {
	const dir = join(project, ".pi");
	const ignore = join(dir, ".gitignore");
	if (existsSync(ignore)) return;
	try {
		mkdirSync(dir, { recursive: true });
		writeFileSync(ignore, "*\n", { flag: "wx" });
	} catch {
		// An unwritable repo is not a reason to fail a session.
	}
}

/** The files this extension contributes for `cwd`, in reading order. */
export function contextFilesFor(cwd: string): { path: string; content: string }[] {
	const paths = [...SYSTEM_FILES];
	const rules = findUp(cwd, PROJECT_RULES);
	if (rules) paths.push(rules);
	const files: { path: string; content: string }[] = [];
	for (const path of paths) {
		try {
			files.push({ path, content: readFileSync(path, "utf-8") });
		} catch {
			// A missing file contributes nothing.
		}
	}
	return files;
}

/** Append `extra` to `existing`, skipping any file already there by real path. */
export function mergeContextFiles(
	existing: { path: string; content: string }[],
	extra: { path: string; content: string }[],
): void {
	const seen = new Set(existing.map((file) => realpath(file.path)));
	for (const file of extra) {
		const key = realpath(file.path);
		if (seen.has(key)) continue;
		seen.add(key);
		existing.push(file);
	}
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
		options.contextFiles ??= [];
		mergeContextFiles(options.contextFiles, contextFilesFor(options.cwd ?? ctx.cwd));
	});
}
