const path = require("path");

const isProd = process.env.NODE_ENV === "prod";

module.exports = {
  mode: isProd ? "production" : "development",

  entry: "./js/app.js",
  output: {
    path: path.resolve(__dirname, "../priv/static/js"),
    filename: "bundle.js"
  },

  resolve: {
    modules: ["node_modules", __dirname + "/js"],
    extensions: [".js", ".html"]
  },

  module: {
    rules: [
      {
        test: /\.(html|svelte|js)$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader",
          options: {
            presets: [["env", { modules: false }]]
          }
        }
      },
      {
        test: /\.(html|svelte)$/,
        exclude: /node_modules/,
        use: {
          loader: "svelte-loader",
          options: {
            // emitCss: true,
            // cascade: false
            hydratable: true
          }
        }
      }
    ]
  }
};
