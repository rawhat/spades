require("esbuild").build({
  entryPoints: ["src/index.tsx"],
  bundle: true,
  outfile: '../priv/static/app.js',
}).catch((err) => {
  console.error("Failed to build", err);
  process.exit(1)
});
