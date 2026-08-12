# OptMem

Permanent memory for AI agents, one memory per project. A short prompt, a
script, plug and play.

A fork of [VictorTaelin/OptMem](https://github.com/VictorTaelin/OptMem), where
the memory is one per machine. Everything below that is not about *where* the
memory lives is his design.

![how OptMem works](anim/optmem.gif)

## Install

From a clone — this installs the copy you are looking at:

```sh
sh install.sh
```

Or from the network:

```sh
curl -fsSL https://raw.githubusercontent.com/StockParrot/OptMem/main/install.sh | sh
```

Set `$OPTMEM_REPO` and `$OPTMEM_REF` to download from a fork or a branch
instead. The installer refuses to finish if the copy it installed is too old
to know about per-project memory, rather than leaving you to find out mid
session.

It prints a `## Memory` block. Paste that at the top of your agent's **global**
`AGENTS.md` (or `CLAUDE.md`) — once, for every project. Run either line again
to update.

The tool lands at `~/.optmem/memo`; put `~/.optmem` on `PATH` to type `memo`.

That is the whole setup. There is no per-project step.

## One memory per project

The first `memo wake` inside a project creates a `memo/` folder at its root,
and says which folder it chose. Every command finds it from then on by walking
up from the current directory, the way `git` finds `.git`. So the same tool,
run in two projects, reads two separate memories — no environment variable, no
configuration, and no way to mix them.

```
~/projects/rubberDuckiesSVGs/memo/    the duck memory
~/projects/fruitSaladWebsite/memo/    the salad memory
```

Nothing needs preparing first. `wake` is the session's opening call, so it
makes the memory itself rather than spending two round trips having one made
and then waking again.

Every *other* command refuses when it finds no memory, and so does `wake` when
`$MEMORY_DIR` names a store that is not there. A path you gave by hand is a
claim about one specific memory, and the answer to a typo in it must never be
a blank one: waking with no past looks exactly like amnesia.

This is the whole of the design. Identity — who you work with, how they like
things — belongs in `CLAUDE.md`, which is loaded every session anyway. The
memory is for the evolving record of the work, and that record is per project.

## Commands

| | |
|---|---|
| `memo wake` | read the memory — the first command of every session |
| `memo note "..."` | record one memory: one line, up to 280 bytes |
| `memo nap` | answer the merges that came due |
| `memo recall <regex>` | search every memory ever recorded, word for word |
| `memo zoom <lo>-<hi>` | open a tree node into its two halves |
| `memo forget <lo>-<hi>` | drop a bad summary; the next nap rebuilds it |

Merges arrive one at a time, in the output of `note`. Nothing ever runs in the
background.

## Files

```
~/.optmem/
  memo          the tool: one file of Python 3, no dependencies
                installed once, shared by every project

<project>/
  memo/
    LOG.txt     every memory, one per line, append-only, never edited
    TREE/       the summaries: a cache, rebuildable from the log alone
    config      the sizes, written by `memo config`
```

```sh
memo config                  # show the sizes
memo config WAKE_LINES=300   # how many lines wake prints (96 ≈ 8k tokens)
memo config WAKE_LINES=      # back to the default
```

`WAKE_LINES` is the only size worth touching, and it is a reading budget, not
a storage budget: change it whenever, in either direction, and nothing is
recomputed.

Records are fixed width, so position *is* identity and every lookup is one
seek. At a million memories (608 MB), `wake` takes 0.03s.

Set `$MEMORY_DIR` to name one store outright, ignoring the search — for a
memory kept outside its project, or a synced folder.

## The prompt

This is what the installer prints, and the whole of the integration.

```markdown
## Memory

Your memory is OptMem:
- The tool is `~/.optmem/memo`
- Your memories live in the `memo/` folder at the root of the project
  you are working in.

OptMem outlives every session, compaction, model and vendor change.
Without it you do not know what was decided and tried.

### At startup: activating OptMem (mandatory)

Run `~/.optmem/memo wake` before any other tool call, in every session, and
then do exactly what it prints, to the end of its output.

### While working: register memories (mandatory)

Call `~/.optmem/memo note "<1 line, max 280 bytes>"` whenever you learn
something new, or something worth keeping happens. That covers a task
worth real effort, a fact or insight the user teaches you, anything you
learn about their life (even indirectly), any event of lasting effect.

Do not register redundant memories.

If `~/.optmem/memo note` asks a compression: do it before your next action.

Never edit or delete anything under `memo/`: the tool manages it.

### When you need an old memory: search, or navigate

`~/.optmem/memo recall <regex>` searches every memory, word for word.

Your memories also form a binary tree: #0-1, #2-3 ... exist as one-line
summaries, pairs of those as #0-3, and so on -- every `#a-b` line wake
prints is one node of it. `~/.optmem/memo zoom <a-b>` opens a node into its
two halves, down to the raw memories.

### If you're a subagent: skip everything above

Parallel sessions on this machine are all you, and may all write memories.
A subagent is not: it must never run `memo`, because it cannot judge what
is already known, and its notes would arrive duplicated and incorrectly.
When you spawn one, write: `You are a subagent. Don't run memo.`
```
