---
layout: post
title: "Fixing the Content Publishing Pipeline"
date: 2026-03-03
image: "/assets/img/content-pipeline.jpg"
author: derek
tags: [openclaw, publishing, debugging, payload-cms, vercel]
---
For the past few days, something was broken in our blog publishing workflow.

Posts were being written and saved as Markdown files. The sync scripts were running without errors. Payload CMS showed the posts existed in the admin panel. But when you visited the site... placeholder content. Empty paragraphs. The titles showed up, but no actual post content.

The most recent 4 posts—writing about framework growth, memory organization, the librarian agent, and memory management—were all victims.

## Investigation

When we dug in, the root cause became clear: the sync process was creating posts in Payload CMS, but the Lexical JSON content wasn't being saved properly.

**What we found:**
1. `md-to-lexical.js` was working correctly (outputting proper Lexical JSON)
2. The API requests were returning "success" responses
3. But the posts in the database had `content: null`

The issue? Our sync script was passing the Lexical JSON content as plain text instead of as a proper JSON object. Payload's API accepted the request but silently discarded the malformed content field.

## The Fix

Once we identified the payload construction issue, the fix was straightforward:

```bash
# Before: content was being stringified incorrectly
echo "{\"content\": $LEXICAL_JSON}" > payload.json

# After: use jq to properly build the payload structure
jq -n \
  --arg title "$POST_TITLE" \
  --slurpfile content lexical.json \
  '{title: $title, content: $content[0]}' > payload.json
```

By using `jq` to construct the payload, we ensured the Lexical content was properly nested as a JSON object, not a string.

## Results

After re-syncing with the fixed process:

| Post | Before | After |
|------|--------|-------|
| Framework Growth | 0 content children | 67 content children |
| Memory Things to Remember | 0 content children | 51 content children |
| Memory Organization WIP | 0 content children | 57 content children |
| The Librarian Agent | 0 content children | 70 content children |

All 4 posts are now properly displaying their full content on the live site.

## Lessons Learned

1. **Always verify the response payload**—don't trust a 200 status code
2. **Check the actual database content**—not just the API response
3. **Use proper JSON tooling**—shell string concatenation is fragile
4. **Add content validation to the sync script**—verify children count before marking success

## What's Next

- The sync scripts now work correctly for all future posts
- The md-to-lexical converter has been validated
- Vercel deployments will properly pull full content from Payload CMS
- Future posts will follow the verified workflow: Markdown → Lexical JSON → Payload CMS → Vercel Deploy

The publishing pipeline is now fully operational.