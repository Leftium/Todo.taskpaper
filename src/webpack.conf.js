
module.exports = {
  entry: './src/index.coffee',
  output: {
    filename: './src/bundle.js'
  },
  resolve: {
    extensions: ['', '.ts', '.js', '.coffee']
  },
  bail: true,
  module: {
    loaders: [
      { test: /\.ts$/, loader: 'ts-loader' },
      { test: /\.coffee$/, loader: 'babel?presets[]=es2015!coffee-loader' },
      { test: /\.css$/, loader: 'style-loader!css-loader' },
    ]
  }
}
