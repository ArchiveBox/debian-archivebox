import { execFileSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';

const repo = process.env.GITHUB_REPOSITORY;
const version = process.env.ARCHIVEBOX_VERSION;
const tag = `v${version}`;
const sha = process.env.GITHUB_SHA;
if (repo !== 'ArchiveBox/debian-archivebox' || !/^\d+\.\d+\.\d+$/.test(version || '') || !/^[0-9a-f]{40}$/.test(sha || '')) throw new Error('Invalid release context');
const gh = (...args) => execFileSync('gh', args, { encoding: 'utf8' }).trim();
const releases = JSON.parse(gh('api', `repos/${repo}/releases?per_page=100`));
const previous = releases.filter(r => !r.draft && !r.prerelease && /^v\d+\.\d+\.\d+$/.test(r.tag_name) && r.tag_name !== tag)
  .sort((a, b) => b.created_at.localeCompare(a.created_at))[0]?.tag_name;
const args = ['api', `repos/${repo}/releases/generate-notes`, '-f', `tag_name=${tag}`, '-f', `target_commitish=${sha}`];
if (previous) args.push('-f', `previous_tag_name=${previous}`);
const generated = JSON.parse(gh(...args)).body;
const block = generated.match(/^## (?:New )?Contributors\n[\s\S]*?(?=^## |\*\*Full Changelog|$(?![\s\S]))/m)?.[0] || '';
const contributorLines = block.split('\n').filter(line => !/@pirate\b|Nick Sweeting/i.test(line));
const contributors = contributorLines.slice(1).some(line => line.trim()) ? contributorLines.join('\n').trim() : '';
const compare = previous ? `[\`${previous}...${tag}\`](https://github.com/${repo}/compare/${previous}...${tag})` : `[\`${tag}\`](https://github.com/${repo}/commits/${tag})`;
const range = previous ? `${previous}..${sha}` : sha;
const commits = execFileSync('git', ['log', '--reverse', '--format=%H%x09%s', range], { encoding: 'utf8' }).trim().split('\n').filter(Boolean)
  .map(line => { const [id, subject] = line.split('\t'); return `- [${id.slice(0, 7)}](https://github.com/${repo}/commit/${id}) ${subject}`; }).join('\n');
const notes = `## Install\n\n- 📦 **Debian / Ubuntu via APT:** Add the ArchiveBox repository and install the package:\n\n  \`\`\`bash\n  echo 'deb [trusted=yes] https://archivebox.github.io/debian-archivebox dev main' | sudo tee /etc/apt/sources.list.d/archivebox.list\n  sudo apt update\n  sudo apt install archivebox\n  \`\`\`\n\n- **Install the release asset directly:** Download \`archivebox_${version}_all.deb\` from the Assets section below, then run \`sudo apt install ./archivebox_${version}_all.deb\`.\n\nAfter installation, initialize the packaged collection, start its service, and create an admin user:\n\n\`\`\`bash\ncd /var/lib/archivebox/data\nsudo archivebox install\nsudo systemctl enable --now archivebox\nsudo -u archivebox -H bash -lc 'cd /var/lib/archivebox/data && archivebox manage createsuperuser'\n\`\`\`\n\n[💻 Screenshots](https://archivebox.io/screenshots/) · [📖 Documentation](https://docs.archivebox.io/) · [💬 \`@ArchiveBoxApp\`](https://x.com/ArchiveBoxApp) · [🐞 Report a bug](https://github.com/${repo}/issues?q=sort%3Aupdated-desc+is%3Aissue+state%3Aopen)\n\n**Full Changelog:** ${compare}\n\n## All changes\n\n${commits}\n\nSource: [\`${sha.slice(0, 7)}\`](https://github.com/${repo}/commit/${sha})${contributors ? `\n\n${contributors}` : ''}\n`;
writeFileSync('dist/release-notes.md', notes);
