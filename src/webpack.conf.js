
module.exports = {
  entry: './src/index.ts',
  output: {
    filename: './src/bundle.js'
  },
  resolve: {
    extensions: ['', '.ts', '.js']
  },
  bail: true,
  module: {
    loaders: [
      { test: /\.ts$/, loader: 'ts-loader' },
      { test: /\.css$/, loader: 'style-loader!css-loader' },
    ]
  }
}
