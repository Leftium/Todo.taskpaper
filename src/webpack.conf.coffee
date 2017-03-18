webpack = require 'webpack'
module.exports =
    entry: './src/index.coffee'
    output:
        filename: './src/bundle.js'
    resolve:
        extensions: ['.js', '.coffee']
    bail: true
    module:
        rules: [
            { test: /\.css$/, use: ['style-loader', 'css-loader'] }
            {
                test: /\.coffee$/
                use: [
                    {
                        loader: 'babel-loader'
                        options: {
                            presets: [["env", {
                                "targets": {
                                    "browsers": ["last 2 versions"]
                                }
                            }]]
                        }
                    }
                    'coffee-loader'
                ]
            }
        ]
    plugins: [
      # new webpack.ContextReplacementPlugin(/moment[\/\\]locale$/, /de|fr|hu/)
      new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/)
    ]
  
