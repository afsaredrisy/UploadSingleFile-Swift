const express    = require('express');
const app        = express();
const multer     = require('multer')

var upload = multer({ 
	storage: multer.diskStorage({
		destination: function (req, file, cb) {
			cb(null, '/Users/pardn_chiu/Desktop/sample/UploadSingleFile/nodejs/image');
		},
		filename: function (req, file, cb) {
			cb(null, file.originalname+'-'+Date.now()+file.mimetype); 
		}
	}) 
})
app.post('/upload', upload.single('uploadImage'), function(req, res, next){
	res.json({'success':1, 'msg':'成功上傳'})
});

app.set('port', process.env.PORT || 3000);
app.listen(3000);
