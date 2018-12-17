var fs = require('fs')
// 包装方法wrap，入参为待包装的异步函数
function wrap(func) {
    //包装函数返回的新函数在执行时，将会返回一个Promise对象，
    return function () {
        return new Promise((resolve, reject) => {
            arguments[arguments.length++] = function (err, ...rest) {
                console.log('3333')
                if (err) {
                    reject(err);
                }
                //异步回掉进入的时候将异步结果resolve回去
                resolve(rest);
            }
            console.log('2222')
            //此处可以看出包装函数在执行时实际上还是执行原来的异步函数func,只是对arguments做了修改
            func.apply(this, arguments)
        })
    }
}
//将包装后的文件读取函数放入工具对象util
var util = {};
util.readdir = wrap(fs.readdir);
async function test() {
    console.log('1111')
    //由于util.readdir的返回值是个promise，必须使用await 方式接收才能拿到promise中的内容
    let ret = await util.readdir(__dirname);
    console.log('4444')
    //console.log('ret:', ret)
    return ret;
}
console.log('befor test');
var files = test().then(ses => {
    //console.log('rest:', ses);
    //files.push(ses)
});
console.log(files==[])