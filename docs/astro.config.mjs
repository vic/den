// @ts-check
import { defineConfig, fontProviders } from 'astro/config';
import starlight from '@astrojs/starlight';

import mermaid from 'astro-mermaid';
import catppuccin from "@catppuccin/starlight";

// https://astro.build/config
export default defineConfig({
	experimental: {
		fonts: [
			{
				provider: fontProviders.google(),
				name: "Victor Mono",
				cssVariable: "--sl-font",
			},
		],
	},
	integrations: [
		mermaid({
			theme: 'forest',
			autoTheme: true
		}),
		starlight({
			title: 'den',
			sidebar: [
				{
					label: 'Den',
					items: [
						{ label: 'Overview', slug: 'overview' },
						{ label: 'Motivation', slug: 'motivation', },
						{ label: 'Community', slug: 'community' },
						{ label: 'Contributing', slug: 'contributing' },
						{ label: 'Sponsor', slug: 'sponsor' },
					],
				},
				{
					label: 'Learn',
					items: [
						{ label: 'Core Principles', slug: 'explanation/core-principles' },
						{ label: 'Context System', slug: 'explanation/context-system' },
						{ label: 'Aspects & Functors', slug: 'explanation/aspects' },
						{ label: 'Parametric Aspects', slug: 'explanation/parametric' },
						{ label: 'NixOS Context Pipeline', slug: 'explanation/context-pipeline' },
						{ label: 'Library vs Framework', slug: 'explanation/library-vs-framework' },
					],
				},
				{
					label: 'Templates',
					items: [
						{ label: 'Overview', slug: 'tutorials/overview' },
						{ label: 'Minimal', slug: 'tutorials/minimal' },
						{ label: 'Default', slug: 'tutorials/default' },
						{ label: 'Example', slug: 'tutorials/example' },
						{ label: 'No-Flake', slug: 'tutorials/noflake' },
						{ label: 'Bug Reproduction', slug: 'tutorials/bogus' },
						{ label: 'CI Tests', slug: 'tutorials/ci' },
					],
				},
				{
					label: 'Cookbook',
					items: [
						{ label: 'Declare Hosts & Users', slug: 'guides/declare-hosts' },
						{ label: 'Configure Aspects', slug: 'guides/configure-aspects' },
						{ label: 'Home-Manager Integration', slug: 'guides/home-manager' },
						{ label: 'Use Batteries', slug: 'guides/batteries' },
						{ label: 'Share with Namespaces', slug: 'guides/namespaces' },
						{ label: 'Angle Brackets Syntax', slug: 'guides/angle-brackets' },
						{ label: 'Custom Nix Classes', slug: 'guides/custom-classes' },
						{ label: 'Migrate to Den', slug: 'guides/migrate' },
						{ label: 'Debug Configurations', slug: 'guides/debug' },
					],
				},
				{
					label: 'Reference',
					items: [
						{ label: 'den.ctx', slug: 'reference/ctx' },
						{ label: 'den.lib', slug: 'reference/lib' },
						{ label: 'den.aspects', slug: 'reference/aspects' },
						{ label: 'den.base', slug: 'reference/schema' },
						{ label: 'den.provides', slug: 'reference/batteries' },
						{ label: 'flake.*', slug: 'reference/output' },
					],
				},
			],
			components: {
				Sidebar: './src/components/Sidebar.astro',
				Footer: './src/components/Footer.astro',
				SocialIcons: './src/components/SocialIcons.astro',
				PageSidebar: './src/components/PageSidebar.astro',
			},
			plugins: [
				catppuccin({
					dark: { flavor: "macchiato", accent: "mauve" },
					light: { flavor: "latte", accent: "mauve" },
				}),
			],
			editLink: {
				baseUrl: 'https://github.com/vic/den/edit/main/docs/',
			},
			customCss: [
				'./src/styles/custom.css'
			],
		}),
	],
});
