import plugin from "tailwindcss/plugin";

// Example Container debug
// <aside class="text-xs absolute left-0 top-0 z-50 flex">
// 	<div
// 		title="Current Container breakpoint"
// 		class="flex items-center space-x-1 bg-yellow-200 p-2 text-yellow-800"
// 	>
// 		<svg
// 			class="w-4 h-4 fill-current"
// 			alt=""
// 			aria-hidden="true"
// 			viewBox="0 0 496.8 496.8"
// 		>
// 			<path d="M118 377.8l-64-64c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l64 64c3.2 3.2 6.4 4.8 11.2 4.8s8-1.6 11.2-4.8c6.4-6.4 6.4-16 0-22.4z" />
// 			<path d="M486 107.4l-96-96a39.7 39.7 0 00-54.4 0L10.8 334.6a39.6 39.6 0 000 54.4l96 96c8 8 17.6 11.2 27.2 11.2 9.6 0 19.2-3.2 25.6-11.2L486 161.8c14.4-16 14.4-40 0-54.4zm-24 30.4L137.2 462.6c-3.2 3.2-4.8 3.2-8 0l-96-96c-1.6-1.6-1.6-6.4 0-8L356.4 33.8c1.6-1.6 3.2-1.6 4.8-1.6 1.6 0 3.2 0 4.8 1.6l96 96c1.6 1.6 1.6 6.4 0 8z" />
// 			<path d="M258.8 237l-64-64c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l64 64c3.2 3.2 6.4 4.8 11.2 4.8s8-1.6 11.2-4.8c6.4-6.4 6.4-16 0-22.4zm-72 22.4l-40-38.4c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l40 38.4c3.2 3.2 6.4 4.8 11.2 4.8s9.6-1.6 11.2-4.8c6.4-6.4 6.4-16 0-22.4zm-46.4 46.4L102 267.4c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l38.4 38.4c3.2 3.2 6.4 4.8 11.2 4.8 4.8 0 8-1.6 11.2-4.8 6.4-6.4 6.4-16 0-22.4zm187.2-187.2l-38.4-38.4c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l38.4 38.4c3.2 3.2 6.4 4.8 11.2 4.8 4.8 0 9.6-1.6 11.2-4.8 6.4-6.4 6.4-16 0-22.4zM281.2 165l-38.4-38.4c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l38.4 38.4c3.2 3.2 6.4 4.8 11.2 4.8s8-1.6 11.2-4.8c6.4-6.4 6.4-16 0-22.4zm118.4-68.8l-64-64c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l64 64c3.2 3.2 6.4 4.8 11.2 4.8 4.8 0 8-1.6 11.2-4.8 6.4-6.4 6.4-16 0-22.4z" />
// 		</svg>
// 		<span class="container-breakpoint"></span>
// 	</div>
// </aside>

// Example Screen debug
// <aside class="text-xs fixed bottom-1 right-1 z-50 flex divide-x divide-solid divide-white shadow-sm" >
//   <span title="Current Screen breakpoint" class="flex items-center space-x-1 bg-yellow-200 p-2 text-yellow-800" >
//   <svg class="w-4 h-4 fill-current" alt="" aria-hidden="true"  viewBox="0 0 496.8 496.8"><path d="M118 377.8l-64-64c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l64 64c3.2 3.2 6.4 4.8 11.2 4.8s8-1.6 11.2-4.8c6.4-6.4 6.4-16 0-22.4z"/><path d="M486 107.4l-96-96a39.7 39.7 0 00-54.4 0L10.8 334.6a39.6 39.6 0 000 54.4l96 96c8 8 17.6 11.2 27.2 11.2 9.6 0 19.2-3.2 25.6-11.2L486 161.8c14.4-16 14.4-40 0-54.4zm-24 30.4L137.2 462.6c-3.2 3.2-4.8 3.2-8 0l-96-96c-1.6-1.6-1.6-6.4 0-8L356.4 33.8c1.6-1.6 3.2-1.6 4.8-1.6 1.6 0 3.2 0 4.8 1.6l96 96c1.6 1.6 1.6 6.4 0 8z"/><path d="M258.8 237l-64-64c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l64 64c3.2 3.2 6.4 4.8 11.2 4.8s8-1.6 11.2-4.8c6.4-6.4 6.4-16 0-22.4zm-72 22.4l-40-38.4c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l40 38.4c3.2 3.2 6.4 4.8 11.2 4.8s9.6-1.6 11.2-4.8c6.4-6.4 6.4-16 0-22.4zm-46.4 46.4L102 267.4c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l38.4 38.4c3.2 3.2 6.4 4.8 11.2 4.8 4.8 0 8-1.6 11.2-4.8 6.4-6.4 6.4-16 0-22.4zm187.2-187.2l-38.4-38.4c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l38.4 38.4c3.2 3.2 6.4 4.8 11.2 4.8 4.8 0 9.6-1.6 11.2-4.8 6.4-6.4 6.4-16 0-22.4zM281.2 165l-38.4-38.4c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l38.4 38.4c3.2 3.2 6.4 4.8 11.2 4.8s8-1.6 11.2-4.8c6.4-6.4 6.4-16 0-22.4zm118.4-68.8l-64-64c-6.4-6.4-16-6.4-22.4 0-6.4 6.4-6.4 16 0 22.4l64 64c3.2 3.2 6.4 4.8 11.2 4.8 4.8 0 8-1.6 11.2-4.8 6.4-6.4 6.4-16 0-22.4z"/></svg>
//     <span class="breakpoint"></span>
//   </span>
// </aside>

// Config values
// const theme = {
//   extends: {
//     screens: {
//       xl: '1200px',
//     },
//     // containers have to be in rem for the debug display to work.
//     containers: {
//       contact: '15rem',
//     },
//   }
// }

export default plugin(({ addBase, theme }) => {
	const ascending = (a: [string, string], b: [string, string]) =>
		Number(a[1].replace(/\D/g, "")) - Number(b[1].replace(/\D/g, ""));

	const makeConfig = (
		themeConfig: string,
		className: string,
		getQuery: (value: [string, string]) => string,
	) => ({
		[`${className}:before`]: {
			display: "block",
			color: theme("colors.yellow.900"),
			textTransform: "uppercase",
			content: '"-"',
		},
		...Object.entries(theme<Record<string, string>>(themeConfig, {}))
			.filter((value) => typeof value[1] === "string")
			.sort(ascending)
			.reduce(
				(acc, value) => ({
					...acc,
					[getQuery(value)]: {
						[`${className}::before`]: {
							content: `"${value[0]}"`,
						},
					},
				}),
				{},
			),
	});

	addBase({
		...makeConfig(
			"screens",
			".breakpoint",
			(value: [string, string]) => `@media (min-width: ${value[1]})`,
		),
		...makeConfig(
			"containers",
			".container-breakpoint",
			(value: [string, string]) => `@container (min-width: ${value[1]})`,
		),
	});
});
