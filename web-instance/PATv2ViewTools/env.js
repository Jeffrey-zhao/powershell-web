var minimist =require('minimist');
var knownOptions = {
    string: 'env',
    default: { env: process.env.NODE_ENV || 'production' }
  };
  
var options = minimist(process.argv.slice(2), knownOptions);

module.exports.env=options.env