var util = require('./util')
var psExecutor = {
    send: function (ps,cmdObject, results = []) {
        return new Promise((resolve, reject) => {
			
            ps = util.getCommand(ps,cmdObject)
            if (!ps) {
                reject('request param cmdObject enconters errors...')
            }
            ps.invoke()
                .then(function (data) {
                    results += data
					resolve(results)
                }).catch(err => {
                     console.log(err);
					    results += data
						reject(data)
                 //ps.dispose();
                });
        })
    }
}

module.exports = psExecutor