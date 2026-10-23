export function errorHandler(err,req,res,next) {
  const status=err.status||500;
  const message=status===413?'La petición es demasiado grande.':status===500?'Ocurrió un error interno.':status===400&&err.type==='entity.parse.failed'?'JSON inválido.':err.message;
  res.status(status).json({success:false,error:message});
}
