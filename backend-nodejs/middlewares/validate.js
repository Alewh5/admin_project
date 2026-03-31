/**
 * @param {import('zod').ZodSchema} schema
 */
const validate = (schema) => (req, res, next) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
        const errores = result.error.issues.map((e) => ({
            campo: e.path.join('.') || 'body',
            mensaje: e.message
        }));
        return res.status(400).json({
            error: 'Datos de entrada inválidos.',
            detalles: errores
        });
    }

    req.body = result.data;
    next();
};

module.exports = validate;
