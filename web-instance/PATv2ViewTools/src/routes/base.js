var express = require('express'),
    router = express.Router(),
    base_mw=require('../middlewares/base_middleware')

    router.use(base_mw.log)
    
    router.use('/script',base_mw.cmd)
    
module.exports=router