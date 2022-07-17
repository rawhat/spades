require("esbuild")
  .build({
    entryPoints: ["src/index.tsx"],
    bundle: true,
    outfile: "../priv/static/app.js",
    watch: {
      onRebuild(error, result) {
        if (error) {
          console.error("Failed to watch", error);
        } else {
          console.log("Watching successful", result);
        }
      },
    },
  })
  .then(() => {
    console.log("Watching...");
  })
  .catch((err) => {
    console.error("Failed to build", err);
    process.exit(1);
  });
