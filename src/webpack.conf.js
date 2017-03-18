var webpack = require("webpack");
module.exports = {
  entry: './src/index.coffee',
  output: {
    filename: './src/bundle.js'
  },
  resolve: {
    extensions: ['.js', '.coffee']
  },
  bail: true,
  module: {
    loaders: [
      { test: /\.coffee$/, loader: 'babel-loader?presets[]=es2015!coffee-loader' },
      { test: /\.json$/, loader: "json-loader"},
      { test: /\.css$/, loader: 'style-loader!css-loader' },
    ]
  },
  plugins: [
    // new webpack.ContextReplacementPlugin(/moment[\/\\]locale$/, /de|fr|hu/)
    new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/)
  ]
}
