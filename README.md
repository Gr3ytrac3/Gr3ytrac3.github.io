# The OffSec Desk — Gr3ytrac3

Personal security research blog. Built with Hugo, deployed to GitHub Pages.

## Stack

- **Generator**: Hugo (no theme — fully custom)
- **Hosting**: GitHub Pages
- **Writing**: Obsidian → `content/posts/`
- **Deploy**: Push to `main` → GitHub Actions builds and deploys automatically

---

## Local Development

### 1. Install Hugo

```bash
sudo dnf install hugo   # Fedora
hugo version            # verify
```

### 2. Clone the repo

```bash
git clone https://github.com/Gr3ytrac3/Gr3ytrac3.github.io.git
cd Gr3ytrac3.github.io
```

### 3. Preview locally

```bash
hugo server -D
# Open http://localhost:1313
```

---

## Writing a New Post

### Option A — Hugo CLI

```bash
hugo new posts/your-post-slug.md
```

### Option B — Obsidian

Create a new note in your Obsidian vault and copy/move it to `content/posts/`.

Every post needs this frontmatter at the top:

```yaml
---
title: "Your Post Title"
date: 2025-04-19
type: note        # or: blog
slug: your-post-slug
published: true
description: "One sentence summary shown in post header."
tags: ["kernel", "research"]
draft: false
---
```

**Post types:**
- `blog` — long-form research, deep dives
- `note` — quick references, short thoughts, observations

### Images

Put images in `static/images/` and reference them in markdown as:

```markdown
![description](/images/your-screenshot.png)
```

If you paste images in Obsidian (they'll be named `Pasted image YYYYMMDD...`), move them to `static/images/` before publishing.

---

## Deploying

```bash
git add .
git commit -m "post: your post title"
git push origin main
```

GitHub Actions handles the build and deploy. Site live at:
**https://Gr3ytrac3.github.io**

---

## GitHub Pages Setup (one-time)

1. Go to your repo → **Settings** → **Pages**
2. Set **Source** to **GitHub Actions**
3. Push to `main` — first deploy happens automatically

---

## Site Structure

```
.
├── content/
│   ├── _index.md          # Homepage text
│   ├── links.md           # Contact/links page
│   └── posts/             # All blog posts go here
│       ├── _index.md
│       └── your-post.md
├── layouts/
│   ├── index.html         # Homepage layout
│   ├── _default/
│   │   ├── baseof.html    # Base HTML shell
│   │   ├── list.html      # Blog list page
│   │   └── single.html    # Individual post
│   ├── links/
│   │   └── single.html    # Links page layout
│   └── partials/
│       ├── nav.html
│       └── footer.html
├── static/
│   ├── css/main.css       # All styles
│   └── images/            # Post images
├── archetypes/
│   └── posts.md           # New post template
├── hugo.toml              # Site config
└── .github/workflows/
    └── hugo.yml           # Auto-deploy pipeline
```

---

## Customization

All personal info lives in `hugo.toml` under `[params]`. Update:
- `baseURL` → your actual GitHub Pages URL
- `author`, `handle`, `organization`
- Social links: `github`, `twitter`, `linkedin`, `infosec`, `substack`

To update the homepage content (experience, projects, research focus), edit `layouts/index.html` directly.
