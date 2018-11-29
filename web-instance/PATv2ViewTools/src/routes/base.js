var express = require('express'),
    router = express.Router()

    router.use(function(req,res,next){
        console.log('%s %s %s',req.method,req.url,req.path)
        next()
    })

module.exports=router