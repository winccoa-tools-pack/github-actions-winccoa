# Repository strategy

## Recommendation

Start with one repository containing multiple actions.

That is the better tradeoff for a WinCC OA action catalog expected to grow to 20-25 actions, because most of the operational cost is at the repository level:

- branch protection and rulesets
- CI and release workflows
- CODEOWNERS and contribution setup
- security settings and Dependabot
- discoverability and documentation

## Why not one repository per action

One repository per action looks clean at small scale, but with 20-25 actions it usually creates more overhead than value:

- 20-25 repositories to bootstrap and secure
- repeated CI and release plumbing
- repeated docs and examples
- harder dependency updates across all actions
- more fragmented discovery for users

## Recommended split criteria

Keep actions in this repository by default. Split an action into its own repository only when at least one of these becomes true:

1. It needs a separate maintainer group or permission model.
2. It has a very different runtime, for example a compiled action with a heavier toolchain.
3. It changes much faster than the rest and needs independent version tags.
4. It has security or compliance requirements that should not share release automation.
5. It becomes broadly useful outside the WinCC OA action family and deserves its own lifecycle.

## Practical model

Use this repository as the public catalog for common WinCC OA actions:

- syntax checking
- test execution
- log analysis
- project lifecycle helpers
- packaging and documentation helpers

If two or three actions later prove to be special cases, extract only those. Do not optimize for a split before the maintenance pain actually appears.
